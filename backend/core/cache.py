from abc import ABC, abstractmethod
import time
import hashlib
from typing import Optional, Dict
import asyncio

class ResponseCache(ABC):
    @abstractmethod
    def get(self, file_hash: str) -> Optional[dict]:
        pass

    @abstractmethod
    def set(self, file_hash: str, response: dict, ttl_seconds: int):
        pass

class InMemoryResponseCache(ResponseCache):
    def __init__(self, max_size: int = 100):
        self._cache: Dict[str, dict] = {}
        self._in_flight: Dict[str, asyncio.Event] = {} # Cache Stampede Protection
        self.max_size = max_size

    def get(self, file_hash: str) -> Optional[dict]:
        if file_hash in self._cache:
            entry = self._cache[file_hash]
            if time.time() < entry['expires_at']:
                return entry['data']
            else:
                del self._cache[file_hash]
        return None

    def set(self, file_hash: str, response: dict, ttl_seconds: int = 3600):
        if len(self._cache) >= self.max_size:
            self._cache.clear()
        
        self._cache[file_hash] = {
            'data': response,
            'expires_at': time.time() + ttl_seconds
        }

    # Stampede Lock Checks mapping in-flight futures optimally avoiding concurrent execution
    def start_flight(self, file_hash: str) -> asyncio.Event:
        event = asyncio.Event()
        self._in_flight[file_hash] = event
        return event

    def resolve_flight(self, file_hash: str):
        if file_hash in self._in_flight:
            self._in_flight[file_hash].set()
            del self._in_flight[file_hash]

    def get_flight_event(self, file_hash: str) -> Optional[asyncio.Event]:
        return self._in_flight.get(file_hash)

def compute_sha256(file_path: str) -> str:
    sha256_hash = hashlib.sha256()
    with open(file_path, "rb") as f:
        for byte_block in iter(lambda: f.read(4096), b""):
            sha256_hash.update(byte_block)
    return sha256_hash.hexdigest()
