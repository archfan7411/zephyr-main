import asyncio
import websockets

players = {}
player_data = {}
uid_increment = 0

async def handle(websocket, path):
    global uid_increment
    player_id = uid_increment
    uid_increment += 1
    players[player_id] = websocket
    player_data[player_id] = ""
    for pid in players.keys():
        connection = players[pid]
        if pid != player_id:
            await connection.send(f"NEW:{player_id}:")
            await websocket.send(f"NEW:{pid}:")
    try:
        while True:
            data = (await websocket.recv()).decode("utf-8")
            if data.startswith("POS:"):
                data = f"POS:{player_id}:{data[4:]}"
                for pid in players.keys():
                    connection = players[pid]
                    if pid != player_id:
                        await connection.send(data)
    except Exception as e:
        print(e)
        del players[player_id]
        del player_data[player_id]
        
        for pid in players.keys():
            connection = players[pid]
            await connection.send(f"DEL:{player_id}:")
        return

start_server = websockets.serve(handle, 'localhost', 7411)

asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()