from fastapi import Request
from fastapi.responses import JSONResponse

class FurSpeakException(Exception):
    def __init__(self, error_type: str, message: str, status_code: int = 400):
        self.error_type = error_type
        self.message = message
        self.status_code = status_code

def furspeak_exception_handler(request: Request, exc: FurSpeakException):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error_type": exc.error_type, "message": exc.message}
    )
