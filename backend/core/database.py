from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker
from backend.core.config import settings

# Note: In production, settings.DATABASE_URL should be postgresql+asyncpg://...
engine_kwargs = {"echo": False}
if "postgresql" in settings.DATABASE_URL:
    engine_kwargs.update({"pool_size": 20, "max_overflow": 10})

engine = create_async_engine(settings.DATABASE_URL, **engine_kwargs)

AsyncSessionLocal = async_sessionmaker(bind=engine, autoflush=False, expire_on_commit=False)

async def get_db():
    async with AsyncSessionLocal() as session:
        yield session
