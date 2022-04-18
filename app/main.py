import os
import logging
from pathlib import Path
from loguru import logger
from fastapi import FastAPI
from app.api.routes import api
from fastapi import FastAPI, Response
from opentelemetry.propagate import inject
from app.utils import PrometheusMiddleware, metrics, setting_otlp

APP_NAME = os.environ.get("APP_NAME", "index_formation")
OTLP_GRPC_ENDPOINT = os.environ.get("OTLP_GRPC_ENDPOINT", "http://tempo:4317")

def get_application() -> FastAPI:
    logger = logging.getLogger(__name__)    

    application = FastAPI(
        title='index_formation',
        description='',
        debug='True',
    )

    setting_otlp(application, APP_NAME, OTLP_GRPC_ENDPOINT)

    application.add_middleware(PrometheusMiddleware, app_name=APP_NAME, filter_unhandled_paths=True)
    application.add_route("/metrics", metrics)

    class EndpointFilter(logging.Filter):
    # Uvicorn endpoint access log filter
        def filter(self, record: logging.LogRecord) -> bool:
            return record.getMessage().find("GET /metrics") == -1

    # Filter out /endpoint
    logging.getLogger("uvicorn.access").addFilter(EndpointFilter())

    @application.on_event("startup")
    async def startup():
        logger.info('startup our app')

    @application.on_event("shutdown")
    async def shutdown():
        logger.info('shutdown our app')

    application.include_router(
        api.router
    )

    return application


app = get_application()
