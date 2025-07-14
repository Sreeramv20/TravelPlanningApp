from typing import Dict, List, Any, Optional

class ActivityService:
    def __init__(self):
        pass
    
    async def search_activities(
        self,
        location: str,
        date: Optional[str] = None,
        category: Optional[str] = None,
        max_price: Optional[float] = None
    ) -> List[Dict[str, Any]]:
        """
        Search for activities and attractions
        """
        # Mock activity search results
        activities = [
            {
                "name": "Tsukiji Market Tour",
                "description": "Explore the famous fish market and try fresh sushi",
                "category": "food",
                "price": 50.0,
                "duration": 3,
                "location": "Tsukiji, Tokyo",
                "is_selected": True,
                "rating": 4.7,
                "review_count": 450
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
                "review_count": 320
            },
            {
                "name": "Senso-ji Temple Visit",
                "description": "Visit Tokyo's oldest temple and explore Asakusa",
                "category": "culture",
                "price": 25.0,
                "duration": 2,
                "location": "Asakusa, Tokyo",
                "is_selected": False,
                "rating": 4.5,
                "review_count": 890
            }
        ]
        
        return activities
    
    async def get_alternatives(
        self,
        location: str,
        date: str,
        current_selection: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Get alternative activity options
        """
        # Mock alternative activities
        alternatives = [
            {
                "name": "Tokyo Skytree Observation",
                "description": "Visit the tallest tower in Japan for panoramic views",
                "category": "sightseeing",
                "price": 35.0,
                "duration": 2,
                "location": "Sumida, Tokyo",
                "is_selected": False,
                "rating": 4.6,
                "review_count": 1200
            },
            {
                "name": "Shibuya Crossing Experience",
                "description": "Experience the world's busiest pedestrian crossing",
                "category": "sightseeing",
                "price": 15.0,
                "duration": 1,
                "location": "Shibuya, Tokyo",
                "is_selected": False,
                "rating": 4.3,
                "review_count": 2100
            },
            {
                "name": "Traditional Tea Ceremony",
                "description": "Participate in a traditional Japanese tea ceremony",
                "category": "culture",
                "price": 80.0,
                "duration": 2,
                "location": "Ginza, Tokyo",
                "is_selected": False,
                "rating": 4.9,
                "review_count": 180
            }
        ]
        
        return alternatives 