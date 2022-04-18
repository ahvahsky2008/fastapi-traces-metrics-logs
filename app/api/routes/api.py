from fastapi import APIRouter

from app.api.routes import index_api

router = APIRouter()
router.include_router(index_api.router, prefix='/api/v1', tags=["API"])
