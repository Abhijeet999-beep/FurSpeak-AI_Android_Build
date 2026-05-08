from sqlalchemy import Column, String, JSON, DateTime, ForeignKey, Index
from datetime import datetime
from backend.models.base import Base


class Job(Base):
    __tablename__ = "jobs"

    id = Column(String, primary_key=True)  # UUID
    user_id = Column(String, ForeignKey("users.id"), nullable=True)  # nullable for guest users
    status = Column(String, default="processing", index=True)  # processing | completed | failed | expired
    request_hash = Column(String, nullable=True)  # M1 fix: removed unique=True to allow re-uploads after expiry
    result_json = Column(JSON, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Composite index for efficient idempotency lookups
    __table_args__ = (
        Index("ix_jobs_hash_status", "request_hash", "status"),
        Index("ix_jobs_user_id", "user_id"),
    )
