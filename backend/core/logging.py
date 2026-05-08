import logging
import json
import traceback
from datetime import datetime, timezone
import contextvars

# Context variables for tracing and request metadata
trace_id_var = contextvars.ContextVar("trace_id", default="")
endpoint_var = contextvars.ContextVar("endpoint", default="")
method_var = contextvars.ContextVar("method", default="")
user_id_var = contextvars.ContextVar("user_id", default="")
job_id_var = contextvars.ContextVar("job_id", default="")

class JSONLogFormatter(logging.Formatter):
    def format(self, record):
        log_obj = {
            "timestamp": datetime.fromtimestamp(record.created, tz=timezone.utc).isoformat(),
            "level": record.levelname,
            "message": record.getMessage(),
            "name": record.name,
        }
        
        # Add context variables
        trace_id = trace_id_var.get()
        if trace_id:
            log_obj["trace_id"] = trace_id
            
        endpoint = endpoint_var.get()
        if endpoint:
            log_obj["endpoint"] = endpoint
            
        method = method_var.get()
        if method:
            log_obj["method"] = method
            
        user_id = user_id_var.get()
        if user_id:
            log_obj["user_id"] = user_id
            
        job_id = job_id_var.get()
        if job_id:
            log_obj["job_id"] = job_id

        # Exception sanitization (never log raw secrets in stack traces, but log the trace structure)
        if record.exc_info:
            exc_text = "".join(traceback.format_exception(*record.exc_info))
            # Basic sanitization, just to be safe
            exc_text = exc_text.replace("password", "***").replace("token", "***")
            log_obj["exception"] = exc_text

        return json.dumps(log_obj)

def setup_logging():
    # Remove all existing handlers
    for handler in logging.root.handlers[:]:
        logging.root.removeHandler(handler)
        
    handler = logging.StreamHandler()
    handler.setFormatter(JSONLogFormatter())
    
    # Configure root logger
    logging.root.setLevel(logging.INFO)
    logging.root.addHandler(handler)
    
    # Suppress noisy external loggers
    logging.getLogger("uvicorn.access").setLevel(logging.WARNING)
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    
    return logging.getLogger("FurSpeak")

logger = setup_logging()
