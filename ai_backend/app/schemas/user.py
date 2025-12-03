from pydantic import BaseModel, Field

class UserBase(BaseModel):
    email: str
    full_name: str | None = None
    is_active: bool = True
    is_superuser: bool = False

class UserCreate(UserBase):
    password: str

class UserUpdate(UserBase):
    password: str | None = None
    openai_api_key: str | None = None
    anthropic_api_key: str | None = None
    selected_model: str | None = None

class UserInDBBase(UserBase):
    id: str
    openai_api_key: str | None = None
    anthropic_api_key: str | None = None
    selected_model: str | None = None

    class Config:
        from_attributes = True

class User(UserInDBBase):
    pass

class UserInDB(UserInDBBase):
    hashed_password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: str | None = None
