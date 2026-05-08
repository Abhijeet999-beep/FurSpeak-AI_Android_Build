import time
from fastapi import Request
from fastapi.responses import JSONResponse
from collections import defaultdict
import asyncio

class InMemoryRateLimiter:
    def __init__(self, limit: int, window_seconds: int):
        self.limit = limit
        self.window = window_seconds
        # Maps identifier to a list of trailing timestamps
        self.requests = defaultdict(list)
        self.lock = asyncio.Lock()

    async def check_rate_limit(self, identifier: str) -> bool:
        now = time.time()
        async with self.lock:
            # Clean up expired bounds selectively instead of clearing whole cache
            self.requests[identifier] = [req_time for req_time in self.requests[identifier] if now - req_time < self.window]
            
            if len(self.requests[identifier]) >= self.limit:
                return False
            
            self.requests[identifier].append(now)
            
            # Global prune logic (prevent unbounded memory growth for stale IPs)
            if len(self.requests) > 10000:
                self._prune_stale(now)
                
            return True

    def _prune_stale(self, now: float):
        keys_to_delete = []
        for k, v in self.requests.items():
            valid_reqs = [t for t in v if now - t < self.window]
            if not valid_reqs:
                keys_to_delete.append(k)
            else:
                self.requests[k] = valid_reqs
        for k in keys_to_delete:
            del self.requests[k]

from backend.core.exceptions import FurSpeakException

def get_rate_limiter(requests: int, window: int):
    limiter = InMemoryRateLimiter(limit=requests, window_seconds=window)
    
    async def _rate_limit_dependency(request: Request):
        # Fallback chain: user_id -> IP address
        user_id = getattr(request.state, "user_id", None)
        identifier = user_id if user_id else request.client.host
        
        allowed = await limiter.check_rate_limit(identifier)
        if not allowed:
            raise FurSpeakException(
                error_code="RATE_LIMIT_EXCEEDED",
                message="Too many requests. Please slow down.",
                status_code=429
            )
        return None
        
    return _rate_limit_dependency

