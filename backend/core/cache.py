from abc import ABC, abstractmethod
import time
import hashlib
from typing import Optional, Dict
from collections import OrderedDict
import asyncio
import logging

logger = logging.getLogger("FurSpeak-Cache")


class ResponseCache(ABC):
    @abstractmethod
    def get(self, file_hash: str) -> Optional[dict]:
        pass

    @abstractmethod
    def set(self, file_hash: str, response: dict, ttl_seconds: int):
        pass


class InMemoryResponseCache(ResponseCache):
    def __init__(self, max_size: int = 100):
        # H9 fix: Use OrderedDict for proper LRU ordering
        self._cache: OrderedDict[str, dict] = OrderedDict()
        self._in_flight: Dict[str, asyncio.Event] = {}  # Cache Stampede Protection
        self.max_size = max_size

    def get(self, file_hash: str) -> Optional[dict]:
        if file_hash in self._cache:
            entry = self._cache[file_hash]
            if time.time() < entry["expires_at"]:
                # Move to end (most recently used)
                self._cache.move_to_end(file_hash)
                return entry["data"]
            else:
                del self._cache[file_hash]
        return None

    def set(self, file_hash: str, response: dict, ttl_seconds: int = 3600):
        # H9 fix: Evict OLDEST entry instead of clearing entire cache
        while len(self._cache) >= self.max_size:
            evicted_key, _ = self._cache.popitem(last=False)
            logger.debug(f"LRU evicted cache entry: {evicted_key[:12]}...")

        self._cache[file_hash] = {
            "data": response,
            "expires_at": time.time() + ttl_seconds,
        }

    # Stampede Lock — prevents concurrent processing of the same file hash
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
