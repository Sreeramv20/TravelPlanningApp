from fastapi import FastAPI, HTTPException, Depends, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPBearer
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import os
import asyncio
from datetime import datetime, timedelta
import json

from agents.planner_agent import PlannerAgent
from agents.search_agent import SearchAgent
from agents.booking_agent import BookingAgent
from services.flight_service import FlightService
from services.hotel_service import HotelService
from services.activity_service import ActivityService

app = FastAPI(
    title="Travel Concierge Agent API",
    description="AI-powered travel planning and booking API",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()

flight_service = FlightService()
hotel_service = HotelService()
activity_service = ActivityService()

planner_agent = PlannerAgent()
search_agent = SearchAgent()
booking_agent = BookingAgent()

class TripRequest(BaseModel):
    departure_location: str
    destination: str
    start_date: str
    end_date: str
    number_of_travelers: int
    budget: Optional[float] = None
    preferences: Dict[str, Any] = {}

class ItineraryResponse(BaseModel):
    id: str
    flights: List[Dict[str, Any]]
    hotels: List[Dict[str, Any]]
    activities: List[Dict[str, Any]]
    transportation: List[Dict[str, Any]]
    daily_schedule: List[Dict[str, Any]]
    total_cost: float
    currency: str = "USD"
    createdAt: str

class BookingRequest(BaseModel):
    trip_id: str
    traveler_details: List[Dict[str, Any]]
    payment_method: Dict[str, Any]

class BookingResponse(BaseModel):
    booking_id: str
    status: str
    confirmation_numbers: List[str]
    total_amount: float
    currency: str

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.post("/plan-trip", response_model=ItineraryResponse)
async def plan_trip(trip_request: TripRequest, background_tasks: BackgroundTasks):
    """
    Plan a complete trip itinerary using AI agents
    """
    try:
        if trip_request.number_of_travelers <= 0:
            raise HTTPException(status_code=400, detail="Number of travelers must be positive")
        
        if trip_request.budget and trip_request.budget <= 0:
            raise HTTPException(status_code=400, detail="Budget must be positive")
        
        start_date = datetime.fromisoformat(trip_request.start_date.replace('Z', '+00:00'))
        end_date = datetime.fromisoformat(trip_request.end_date.replace('Z', '+00:00'))
        
        if start_date >= end_date:
            raise HTTPException(status_code=400, detail="End date must be after start date")
        
        itinerary = await planner_agent.create_itinerary(
            departure_location=trip_request.departure_location,
            destination=trip_request.destination,
            start_date=start_date,
            end_date=end_date,
            number_of_travelers=trip_request.number_of_travelers,
            budget=trip_request.budget,
            preferences=trip_request.preferences
        )
        
        background_tasks.add_task(save_itinerary, itinerary)

        from datetime import timezone
        itinerary["createdAt"] = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace('+00:00', 'Z')
        itinerary.pop("created_at", None)

        return itinerary
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to plan trip: {str(e)}")

@app.get("/search-flights")
async def search_flights(
    from_location: str,
    to_location: str,
    departure_date: str,
    return_date: Optional[str] = None,
    passengers: int = 1,
    class_type: str = "economy"
):
    """
    Search for available flights
    """
    try:
        flights = await flight_service.search_flights(
            from_location=from_location,
            to_location=to_location,
            departure_date=departure_date,
            return_date=return_date,
            passengers=passengers,
            class_type=class_type
        )
        return {"flights": flights}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to search flights: {str(e)}")

@app.get("/search-hotels")
async def search_hotels(
    location: str,
    check_in: str,
    check_out: str,
    guests: int = 1,
    rooms: int = 1,
    min_stars: Optional[int] = None
):
    """
    Search for available hotels
    """
    try:
        hotels = await hotel_service.search_hotels(
            location=location,
            check_in=check_in,
            check_out=check_out,
            guests=guests,
            rooms=rooms,
            min_stars=min_stars
        )
        return {"hotels": hotels}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to search hotels: {str(e)}")

@app.get("/search-activities")
async def search_activities(
    location: str,
    date: Optional[str] = None,
    category: Optional[str] = None,
    max_price: Optional[float] = None
):
    """
    Search for activities and attractions
    """
    try:
        activities = await activity_service.search_activities(
            location=location,
            date=date,
            category=category,
            max_price=max_price
        )
        return {"activities": activities}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to search activities: {str(e)}")

@app.post("/create-booking", response_model=BookingResponse)
async def create_booking(booking_request: BookingRequest):
    """
    Create a booking for the selected itinerary
    """
    try:
        booking = await booking_agent.create_booking(
            trip_id=booking_request.trip_id,
            traveler_details=booking_request.traveler_details,
            payment_method=booking_request.payment_method
        )
        return booking
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to create booking: {str(e)}")

@app.get("/booking/{booking_id}")
async def get_booking_status(booking_id: str):
    """
    Get the status of a booking
    """
    try:
        booking = await booking_agent.get_booking(booking_id)
        if not booking:
            raise HTTPException(status_code=404, detail="Booking not found")
        return booking
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get booking: {str(e)}")

@app.post("/booking/{booking_id}/cancel")
async def cancel_booking(booking_id: str):
    """
    Cancel a booking
    """
    try:
        result = await booking_agent.cancel_booking(booking_id)
        return {"message": "Booking cancelled successfully", "booking_id": booking_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to cancel booking: {str(e)}")

@app.get("/alternatives/{item_type}")
async def get_alternatives(
    item_type: str,
    location: str,
    date: str,
    current_selection: Optional[str] = None
):
    """
    Get alternative options for flights, hotels, or activities
    """
    try:
        if item_type == "flights":
            alternatives = await flight_service.get_alternatives(location, date, current_selection)
        elif item_type == "hotels":
            alternatives = await hotel_service.get_alternatives(location, date, current_selection)
        elif item_type == "activities":
            alternatives = await activity_service.get_alternatives(location, date, current_selection)
        else:
            raise HTTPException(status_code=400, detail="Invalid item type")
        
        return {"alternatives": alternatives}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get alternatives: {str(e)}")

@app.put("/itinerary/{itinerary_id}")
async def update_itinerary(itinerary_id: str, updates: Dict[str, Any]):
    """
    Update an existing itinerary
    """
    try:
        updated_itinerary = await planner_agent.update_itinerary(itinerary_id, updates)
        return updated_itinerary
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update itinerary: {str(e)}")

@app.get("/pricing/{itinerary_id}")
async def get_pricing_breakdown(itinerary_id: str):
    """
    Get detailed pricing breakdown for an itinerary
    """
    try:
        pricing = await planner_agent.get_pricing_breakdown(itinerary_id)
        return pricing
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get pricing breakdown: {str(e)}")

@app.get("/itinerary/{itinerary_id}/export")
async def export_itinerary(itinerary_id: str, format: str = "pdf"):
    """
    Export itinerary in various formats (PDF, JSON, etc.)
    """
    try:
        if format not in ["pdf", "json", "calendar"]:
            raise HTTPException(status_code=400, detail="Unsupported export format")
        
        export_data = await planner_agent.export_itinerary(itinerary_id, format)
        return export_data
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to export itinerary: {str(e)}")
    
@app.get("/user-preferences/{user_id}")
async def get_user_preferences(user_id: str):
    """
    Get user travel preferences
    """
    try:
        preferences = await planner_agent.get_user_preferences(user_id)
        return preferences
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to get user preferences: {str(e)}")

@app.put("/user-preferences/{user_id}")
async def update_user_preferences(user_id: str, preferences: Dict[str, Any]):
    """
    Update user travel preferences
    """
    try:
        updated_preferences = await planner_agent.update_user_preferences(user_id, preferences)
        return updated_preferences
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to update user preferences: {str(e)}")

# Background task to save itinerary
async def save_itinerary(itinerary: Dict[str, Any]):
    """
    Save itinerary to database (background task)
    """
    try:
        # Need to save to database
        print(f"Saving itinerary {itinerary['id']} to database")
        await asyncio.sleep(1)  #DB operation
    except Exception as e:
        print(f"Failed to save itinerary: {str(e)}")

# Error handlers
@app.exception_handler(404)
async def not_found_handler(request, exc):
    return {"error": "Resource not found", "detail": str(exc)}

@app.exception_handler(500)
async def internal_error_handler(request, exc):
    return {"error": "Internal server error", "detail": str(exc)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000) 