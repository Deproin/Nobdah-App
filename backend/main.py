import json
import asyncio
import uuid
from fastapi import FastAPI, WebSocket, WebSocketDisconnect # type: ignore
from typing import Dict, List, Optional
from fastapi.middleware.cors import CORSMiddleware # type: ignore
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("Nobdah")

app = FastAPI(title="Nobdah API")

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    return {
        "message": "Nobdah Backend is Running",
        "active_users": len(active_connections),
        "queue_size": len(matchmaking_queue),
        "active_sessions": len(active_sessions) // 2
    }

# Store active connections: {client_id: websocket}
active_connections: Dict[str, WebSocket] = {}

# Matchmaking queue: [client_id, ...]
matchmaking_queue: List[str] = []

# Active sessions: {client_id: partner_id}
active_sessions: Dict[str, str] = {}

class ConnectionManager:
    async def connect(self, websocket: WebSocket, client_id: str):
        await websocket.accept()
        active_connections[client_id] = websocket
        logger.info(f"Client {client_id} connected. Total active: {len(active_connections)}")

    def disconnect(self, client_id: str):
        if client_id in active_connections:
            del active_connections[client_id]
        
        # Remove from queue if present
        if client_id in matchmaking_queue:
            matchmaking_queue.remove(client_id)
            logger.info(f"Client {client_id} removed from queue")
            
        # Clean up session
        if client_id in active_sessions:
            partner_id = active_sessions[client_id]
            if partner_id in active_sessions:
                del active_sessions[partner_id]
            del active_sessions[client_id]
            logger.info(f"Session between {client_id} and {partner_id} ended")
            return partner_id
        return None

    async def send_message(self, client_id: str, message: dict):
        if client_id in active_connections:
            try:
                await active_connections[client_id].send_text(json.dumps(message))
            except Exception as e:
                logger.error(f"Error sending message to {client_id}: {e}")
                self.disconnect(client_id)

manager = ConnectionManager()

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    client_id = str(uuid.uuid4())
    await manager.connect(websocket, client_id)
    
    try:
        while True:
            data = await websocket.receive_text()
            message = json.loads(data)
            msg_type = message.get("type")

            if msg_type == "start_matchmaking":
                logger.info(f"Client {client_id} started matchmaking")
                if client_id not in matchmaking_queue:
                    matchmaking_queue.append(client_id)
                
                # Check if we can match
                while len(matchmaking_queue) >= 2:
                    user1 = matchmaking_queue.pop(0)
                    user2 = matchmaking_queue.pop(0)
                    
                    # Ensure they are still connected
                    if user1 not in active_connections:
                        matchmaking_queue.insert(0, user2)
                        continue
                    if user2 not in active_connections:
                        matchmaking_queue.insert(0, user1)
                        continue

                    active_sessions[user1] = user2
                    active_sessions[user2] = user1
                    
                    # Notify both users (one as caller, one as receiver)
                    await manager.send_message(user1, {"type": "match_found", "role": "caller", "partner_id": user2})
                    await manager.send_message(user2, {"type": "match_found", "role": "receiver", "partner_id": user1})
                    logger.info(f"Matched {user1} with {user2}")
                    break

            elif msg_type in ["offer", "answer", "ice-candidate"]:
                # Relay signaling to partner
                partner_id = active_sessions.get(client_id)
                if partner_id:
                    await manager.send_message(partner_id, message)

            elif msg_type == "end_call":
                partner_id = manager.disconnect(client_id)
                if partner_id:
                    await manager.send_message(partner_id, {"type": "call_ended"})
                break

    except WebSocketDisconnect:
        partner_id = manager.disconnect(client_id)
        if partner_id:
            try:
                await manager.send_message(partner_id, {"type": "call_ended"})
            except:
                pass
        logger.info(f"Client {client_id} disconnected. Total active: {len(active_connections)}")

if __name__ == "__main__":
    import uvicorn # type: ignore
    uvicorn.run(app, host="0.0.0.0", port=8000)
