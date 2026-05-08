from pydantic import BaseModel
from typing import Generic, TypeVar, Optional

DataT = TypeVar("DataT")


class BaseResponse(BaseModel, Generic[DataT]):
    success: bool
    data: Optional[DataT] = None
    message: str
    error_code: Optional[str] = None

    @classmethod
    def ok(cls, data: Optional[DataT] = None, message: str = "Success"):
        """Create a success response."""
        return cls(success=True, data=data, message=message)

    @classmethod
    def fail(cls, message: str, error_code: str = "UNKNOWN_ERROR"):
        """Create an error response."""
        return cls(success=False, message=message, error_code=error_code)


# Preserve the old API names — the Pydantic field 'success' shadows the classmethod 'success' 
# on BaseModel, so we alias to 'ok' and 'fail' for clarity, but keep backward-compat wrappers.
_original_success = BaseResponse.ok
_original_error = BaseResponse.fail

# Monkey-patch to support existing code that calls BaseResponse.success(...)
# Pydantic v2 doesn't allow a classmethod named 'success' when there's a field named 'success'
# so we inject it after class creation.
BaseResponse.success = _original_success  # type: ignore[assignment]
BaseResponse.error = _original_error  # type: ignore[assignment]
