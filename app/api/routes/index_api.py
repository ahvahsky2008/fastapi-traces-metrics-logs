import json
from typing import Any, Dict, AnyStr, List, Union

from fastapi import APIRouter
from app.api.routes.log_route import LogRoute
from fastapi.encoders import jsonable_encoder
import logging

router = APIRouter()

logger = logging.getLogger(__name__)

@router.get('/index', name='Список всех индексов на сервере')
def get_index(index: str):
   """
    Возвращает список всех индексов и их `mapping`-и
   """
   x = int(index)

@router.get('/', name='Список всех индексов на сервере')
async def read_root():
   logging.error("Hello World")
   return {"Hello": "World"}