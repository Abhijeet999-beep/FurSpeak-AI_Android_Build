from abc import ABC, abstractmethod
import time
from fastapi import Request, HTTPException, status
from collections import defaultdict

class RateLimiter(ABC):
    @abstractmethod
    def check_rate_limit(self, identifier: str):
        pass

class InMemoryRateLimiter(RateLimiter):
    def __init__(self, limit: int = 10, window_seconds: int = 60):
        self.limit = limit
        self.window = window_seconds
        # Maps identifier to a list of trailing timestamps mapping logic
        self.requests = defaultdict(list)

    def check_rate_limit(self, identifier: str):
        now = time.time()
        # Clean up expired bounds structurally tracking limits dynamically natively 
        self.requests[identifier] = [req_time for req_time in self.requests[identifier] if now - req_time < self.window]
        
        if len(self.requests[identifier]) >= self.limit:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Rate limit exceeded. Please try again later."
            )
        
        self.requests[identifier].append(now)

# Global API Limiter exported scaling safely mapping future Redis limits structurally
api_limiter = InMemoryRateLimiter(limit=100, window_seconds=60)
