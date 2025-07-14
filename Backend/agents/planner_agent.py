import asyncio
import json
import uuid
from datetime import datetime, timedelta, timezone
from typing import Dict, List, Any, Optional
import os
from pydantic import SecretStr
from dotenv import load_dotenv
from langchain_openai import OpenAI
from langchain.chains import LLMChain
from langchain.prompts import PromptTemplate

load_dotenv()

class PlannerAgent:
    def __init__(self):
        self.llm = OpenAI(
            api_key=SecretStr(os.getenv("OPENAI_API_KEY") or ""),
            temperature=0.7,
            max_tokens=2000
        )
        self.itineraries = {}
        
    async def create_itinerary(
        self,
        departure_location: str,
        destination: str,
        start_date: datetime,
        end_date: datetime,
        number_of_travelers: int,
        budget: Optional[float] = None,
        preferences: Dict[str, Any] = {}
    ) -> Dict[str, Any]:
        """
        Create a complete trip itinerary using AI
        """
        itinerary_id = str(uuid.uuid4())
        
        duration = (end_date - start_date).days
        
        planning_prompt = self._create_planning_prompt(
            departure_location=departure_location,
            destination=destination,
            start_date=start_date,
            end_date=end_date,
            duration=duration,
            number_of_travelers=number_of_travelers,
            budget=budget,
            preferences=preferences
        )
        
        itinerary_data = await self._generate_itinerary(planning_prompt)
        
        itinerary = {
            "id": itinerary_id,
            "departure_location": departure_location,
            "destination": destination,
            "start_date": start_date.isoformat(),
            "end_date": end_date.isoformat(),
            "duration": duration,
            "number_of_travelers": number_of_travelers,
            "budget": budget,
            "preferences": preferences,
            "flights": itinerary_data.get("flights", []),
            "hotels": itinerary_data.get("hotels", []),
            "activities": itinerary_data.get("activities", []),
            "transportation": itinerary_data.get("transportation", []),
            "daily_schedule": itinerary_data.get("daily_schedule", []),
            "total_cost": itinerary_data.get("total_cost", 0.0),
            "currency": "USD",
            "createdAt": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace('+00:00', 'Z'),
            "status": "planned"
        }
        
        self.itineraries[itinerary_id] = itinerary

        itinerary["createdAt"] = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace('+00:00', 'Z')
        itinerary.pop("created_at", None)

        return itinerary
    
    def _create_planning_prompt(
        self,
        departure_location: str,
        destination: str,
        start_date: datetime,
        end_date: datetime,
        duration: int,
        number_of_travelers: int,
        budget: Optional[float] = None,
        preferences: Dict[str, Any] = {}
    ) -> str:
        """
        Create a comprehensive planning prompt for the AI
        """
        prompt = f"""
        Plan a complete {duration}-day trip from {departure_location} to {destination} for {number_of_travelers} traveler(s).
        
        Trip Details:
        - Departure: {departure_location}
        - Destination: {destination}
        - Start Date: {start_date.strftime('%Y-%m-%d')}
        - End Date: {end_date.strftime('%Y-%m-%d')}
        - Duration: {duration} days
        - Travelers: {number_of_travelers}
        - Budget: ${budget if budget else 'Flexible'}
        
        Preferences: {json.dumps(preferences, indent=2)}
        
        Please create a comprehensive itinerary including:
        
        1. FLIGHTS: 3-5 flight options with realistic prices, airlines, and schedules
        2. HOTELS: 3-5 hotel options with amenities, ratings, and prices
        3. ACTIVITIES: 8-12 activities covering sightseeing, culture, food, and adventure
        4. TRANSPORTATION: Local transportation options
        5. DAILY SCHEDULE: Day-by-day schedule with activities, meals, and timing
        6. TOTAL COST: Calculate total cost including all components
        
        Return the response as a structured JSON object with the following format:
        {{
            "flights": [
                {{
                    "airline": "Airline Name",
                    "flight_number": "FL123",
                    "departure_time": "2024-01-01T10:00:00",
                    "arrival_time": "2024-01-01T14:00:00",
                    "departure_airport": "JFK",
                    "arrival_airport": "NRT",
                    "price": 1200.0,
                    "class": "economy",
                    "duration": 360,
                    "stops": 0,
                    "is_selected": true
                }}
            ],
            "hotels": [
                {{
                    "name": "Hotel Name",
                    "address": "Hotel Address",
                    "star_rating": 4,
                    "price_per_night": 250.0,
                    "amenities": ["WiFi", "Pool", "Gym"],
                    "room_type": "Deluxe Room",
                    "check_in_date": "2024-01-01",
                    "check_out_date": "2024-01-08",
                    "total_price": 1750.0,
                    "is_selected": true,
                    "rating": 4.5,
                    "review_count": 1250
                }}
            ],
            "activities": [
                {{
                    "name": "Activity Name",
                    "description": "Activity description",
                    "category": "sightseeing",
                    "price": 50.0,
                    "duration": 3,
                    "location": "Activity location",
                    "is_selected": true,
                    "rating": 4.7,
                    "review_count": 450
                }}
            ],
            "transportation": [
                {{
                    "type": "taxi",
                    "provider": "Local Taxi Co.",
                    "price": 80.0,
                    "duration": 60,
                    "is_selected": true
                }}
            ],
            "daily_schedule": [
                {{
                    "date": "2024-01-01",
                    "activities": [
                        {{
                            "name": "Activity Name",
                            "start_time": "09:00",
                            "end_time": "12:00",
                            "location": "Activity location"
                        }}
                    ],
                    "meals": [
                        {{
                            "type": "Breakfast",
                            "estimated_cost": 15.0,
                            "currency": "USD",
                            "time": "08:00"
                        }}
                    ],
                    "transportation": [
                        {{
                            "type": "taxi",
                            "provider": "Local Taxi Co.",
                            "price": 20.0
                        }}
                    ]
                }}
            ],
            "total_cost": 5000.0
        }}
        
        Make sure all prices are realistic and the schedule is logical and enjoyable.
        """
        
        return prompt
    
    async def _generate_itinerary(self, prompt: str) -> Dict[str, Any]:
        """
        Generate itinerary using OpenAI
        """
        try:
            chain = LLMChain(llm=self.llm, prompt=PromptTemplate(
                input_variables=["prompt"],
                template="{prompt}"
            ))
            
            response = await asyncio.to_thread(
                chain.run,
                prompt=prompt
            )
            
            json_start = response.find('{')
            json_end = response.rfind('}') + 1
            
            if json_start != -1 and json_end != 0:
                json_str = response[json_start:json_end]
                itinerary_data = json.loads(json_str)
                for flight in itinerary_data.get("flights", []):
                    if "flight_number" not in flight:
                        flight["flight_number"] = "UNKNOWN"
                itinerary_data["createdAt"] = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace('+00:00', 'Z')
                return itinerary_data
            else:
                mock = self._generate_mock_itinerary()
                mock["createdAt"] = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace('+00:00', 'Z')
                return mock
                
        except Exception as e:
            print(f"Error generating itinerary: {str(e)}")
            return self._generate_mock_itinerary()
    
    def _generate_mock_itinerary(self) -> Dict[str, Any]:
        """
        Generate mock itinerary data for demonstration
        """
        dt_depart = datetime(2024, 1, 1, 10, 0, 0, tzinfo=timezone.utc)
        dt_arrive = datetime(2024, 1, 1, 14, 0, 0, tzinfo=timezone.utc)
        dt_depart2 = datetime(2024, 1, 1, 12, 0, 0, tzinfo=timezone.utc)
        dt_arrive2 = datetime(2024, 1, 1, 16, 0, 0, tzinfo=timezone.utc)
        check_in = datetime(2024, 1, 1, tzinfo=timezone.utc)
        check_out = datetime(2024, 1, 8, tzinfo=timezone.utc)
        day_date = datetime(2024, 1, 1, tzinfo=timezone.utc)
        return {
            "createdAt": datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace('+00:00', 'Z'),
            "flights": [
                {
                    "airline": "Delta Air Lines",
                    "flight_number": "DL123",
                    "departure_time": dt_depart.isoformat().replace('+00:00', 'Z'),
                    "arrival_time": dt_arrive.isoformat().replace('+00:00', 'Z'),
                    "departure_airport": "JFK",
                    "arrival_airport": "NRT",
                    "price": 1200.0,
                    "class": "Economy",
                    "duration": 360,
                    "stops": 0,
                    "is_selected": True,
                    "currency": "USD"
                },
                {
                    "airline": "United Airlines",
                    "flight_number": "UA456",
                    "departure_time": dt_depart2.isoformat().replace('+00:00', 'Z'),
                    "arrival_time": dt_arrive2.isoformat().replace('+00:00', 'Z'),
                    "departure_airport": "JFK",
                    "arrival_airport": "NRT",
                    "price": 1100.0,
                    "class": "Economy",
                    "duration": 360,
                    "stops": 1,
                    "is_selected": False,
                    "currency": "USD"
                }
            ],
            "hotels": [
                {
                    "name": "Hilton Tokyo",
                    "address": "6-6-2 Nishi-Shinjuku, Tokyo",
                    "star_rating": 4,
                    "price_per_night": 250.0,
                    "amenities": ["WiFi", "Pool", "Gym", "Restaurant"],
                    "room_type": "Deluxe Room",
                    "check_in_date": check_in.isoformat().replace('+00:00', 'Z'),
                    "check_out_date": check_out.isoformat().replace('+00:00', 'Z'),
                    "total_price": 1750.0,
                    "is_selected": True,
                    "rating": 4.5,
                    "review_count": 1250,
                    "currency": "USD",
                    "images": []
                }
            ],
            "activities": [
                {
                    "name": "Tsukiji Market Tour",
                    "description": "Explore the famous fish market and try fresh sushi",
                    "category": "food",
                    "price": 50.0,
                    "duration": 3,
                    "location": "Tsukiji, Tokyo",
                    "is_selected": True,
                    "rating": 4.7,
                    "review_count": 450,
                    "currency": "USD",
                    "images": []
                },
                {
                    "name": "Mount Fuji Day Trip",
                    "description": "Visit the iconic Mount Fuji and surrounding areas",
                    "category": "sightseeing",
                    "price": 120.0,
                    "duration": 8,
                    "location": "Mount Fuji",
                    "is_selected": True,
                    "rating": 4.8,
                    "review_count": 320,
                    "currency": "USD",
                    "images": []
                }
            ],
            "transportation": [
                {
                    "type": "Taxi",
                    "provider": "Tokyo Taxi Co.",
                    "price": 80.0,
                    "duration": 60,
                    "is_selected": True,
                    "currency": "USD"
                }
            ],
            "daily_schedule": [
                {
                    "date": day_date.isoformat().replace('+00:00', 'Z'),
                    "activities": [
                        {
                            "activity": {
                                "name": "Tsukiji Market Tour",
                                "description": "Explore the famous fish market and try fresh sushi",
                                "category": "food",
                                "price": 50.0,
                                "duration": 3,
                                "location": "Tsukiji, Tokyo",
                                "is_selected": True,
                                "rating": 4.7,
                                "review_count": 450,
                                "currency": "USD",
                                "images": []
                            },
                            "start_time": datetime(2024, 1, 1, 9, 0, 0, tzinfo=timezone.utc).isoformat().replace('+00:00', 'Z'),
                            "end_time": datetime(2024, 1, 1, 12, 0, 0, tzinfo=timezone.utc).isoformat().replace('+00:00', 'Z'),
                            "location": "Tsukiji, Tokyo"
                        }
                    ],
                    "meals": [
                        {
                            "type": "Breakfast",
                            "estimated_cost": 15.0,
                            "currency": "USD",
                            "time": datetime(2024, 1, 1, 8, 0, 0, tzinfo=timezone.utc).isoformat().replace('+00:00', 'Z')
                        },
                        {
                            "type": "Lunch",
                            "estimated_cost": 25.0,
                            "currency": "USD",
                            "time": datetime(2024, 1, 1, 13, 0, 0, tzinfo=timezone.utc).isoformat().replace('+00:00', 'Z')
                        },
                        {
                            "type": "Dinner",
                            "estimated_cost": 35.0,
                            "currency": "USD",
                            "time": datetime(2024, 1, 1, 19, 0, 0, tzinfo=timezone.utc).isoformat().replace('+00:00', 'Z')
                        }
                    ],
                    "transportation": [
                        {
                            "type": "Taxi",
                            "provider": "Tokyo Taxi Co.",
                            "price": 20.0,
                            "duration": 0,
                            "is_selected": False,
                            "currency": "USD"
                        }
                    ]
                }
            ],
            "total_cost": 5000.0
        }
    
    async def update_itinerary(self, itinerary_id: str, updates: Dict[str, Any]) -> Dict[str, Any]:
        """
        Update an existing itinerary
        """
        if itinerary_id not in self.itineraries:
            raise ValueError("Itinerary not found")
        
        itinerary = self.itineraries[itinerary_id]
        itinerary.update(updates)
        itinerary["updated_at"] = datetime.now().isoformat()
        
        return itinerary
    
    async def get_pricing_breakdown(self, itinerary_id: str) -> Dict[str, Any]:
        """
        Get detailed pricing breakdown for an itinerary
        """
        if itinerary_id not in self.itineraries:
            raise ValueError("Itinerary not found")
        
        itinerary = self.itineraries[itinerary_id]

        flight_cost = sum(flight["price"] for flight in itinerary["flights"] if flight.get("is_selected", False))
        hotel_cost = sum(hotel["total_price"] for hotel in itinerary["hotels"] if hotel.get("is_selected", False))
        activity_cost = sum(activity["price"] for activity in itinerary["activities"] if activity.get("is_selected", False))
        transport_cost = sum(transport["price"] for transport in itinerary["transportation"] if transport.get("is_selected", False))
        
        daily_food_cost = 60.0
        food_cost = daily_food_cost * itinerary["number_of_travelers"] * itinerary["duration"]
        
        total_cost = flight_cost + hotel_cost + activity_cost + transport_cost + food_cost
        
        return {
            "itinerary_id": itinerary_id,
            "breakdown": {
                "flights": flight_cost,
                "hotels": hotel_cost,
                "activities": activity_cost,
                "transportation": transport_cost,
                "food": food_cost
            },
            "total_cost": total_cost,
            "currency": "USD"
        }
    
    async def export_itinerary(self, itinerary_id: str, format: str) -> Dict[str, Any]:
        """
        Export itinerary in various formats
        """
        if itinerary_id not in self.itineraries:
            raise ValueError("Itinerary not found")
        
        itinerary = self.itineraries[itinerary_id]
        
        if format == "json":
            return itinerary
        elif format == "pdf":
            return {"message": "PDF export not implemented yet", "itinerary_id": itinerary_id}
        elif format == "calendar":
            events = []
            for day in itinerary["daily_schedule"]:
                for activity in day["activities"]:
                    events.append({
                        "title": activity["name"],
                        "start": f"{day['date']}T{activity['start_time']}:00",
                        "end": f"{day['date']}T{activity['end_time']}:00",
                        "location": activity["location"]
                    })
            return {"events": events}
        else:
            raise ValueError("Unsupported export format")
    
    async def get_user_preferences(self, user_id: str) -> Dict[str, Any]:
        """
        Get user travel preferences
        """
        return {
            "user_id": user_id,
            "preferences": {
                "flight_class": "economy",
                "hotel_star_rating": 3,
                "include_activities": True,
                "include_transportation": True,
                "preferred_airlines": [],
                "preferred_hotel_chains": [],
                "dietary_restrictions": [],
                "accessibility_needs": []
            }
        }
    
    async def update_user_preferences(self, user_id: str, preferences: Dict[str, Any]) -> Dict[str, Any]:
        """
        Update user travel preferences
        """
        return {
            "user_id": user_id,
            "preferences": preferences,
            "updated_at": datetime.now().isoformat()
        } 