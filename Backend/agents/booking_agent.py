import uuid
from typing import Dict, List, Any, Optional
from datetime import datetime

class BookingAgent:
    def __init__(self):
        self.bookings = {} 
    
    async def create_booking(
        self,
        trip_id: str,
        traveler_details: List[Dict[str, Any]],
        payment_method: Dict[str, Any]
    ) -> Dict[str, Any]:
        """
        Create a booking for the selected itinerary
        """
        booking_id = str(uuid.uuid4())
        
        confirmation_numbers = [
            f"FL-{uuid.uuid4().hex[:6].upper()}",
            f"HT-{uuid.uuid4().hex[:6].upper()}",
            f"AC-{uuid.uuid4().hex[:6].upper()}"
        ]
        
        total_amount = 5000.0
        
        booking = {
            "booking_id": booking_id,
            "trip_id": trip_id,
            "traveler_details": traveler_details,
            "payment_method": payment_method,
            "total_amount": total_amount,
            "currency": "USD",
            "status": "confirmed",
            "confirmation_numbers": confirmation_numbers,
            "created_at": datetime.now().isoformat()
        }

        self.bookings[booking_id] = booking
        
        return booking
    
    async def get_booking(self, booking_id: str) -> Optional[Dict[str, Any]]:
        """
        Get booking details
        """
        return self.bookings.get(booking_id)
    
    async def cancel_booking(self, booking_id: str) -> bool:
        """
        Cancel a booking
        """
        if booking_id in self.bookings:
            self.bookings[booking_id]["status"] = "cancelled"
            self.bookings[booking_id]["cancelled_at"] = datetime.now().isoformat()
            return True
        return False 