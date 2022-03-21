# https://stackoverflow.com/questions/48506460/python-simple-socket-client-server-using-asyncio

import asyncio, socket

crew = {} # key is player ID, value is [writer, position]

protocol_version = 2

# protocol changelog
# 2: Added client code 5 and server code 6 (DAMAGEPLAYER)

SERVER_INIT = 1
SERVER_NEWPLAYER = 2
SERVER_UPDATEPLAYER = 3
SERVER_DELETEPLAYER = 4
SERVER_CHATMESSAGE = 5
SERVER_DAMAGEPLAYER = 6

async def send_chat_message(player_id, message):
    writer = crew[player_id][0]
    message_bytes = message.encode(encoding = "UTF-8", errors = "replace")
    len_bytes = len(message_bytes)
    writer.write(SERVER_CHATMESSAGE.to_bytes(2, "little", signed=False))
    writer.write(len_bytes.to_bytes(4, "little", signed=False))
    writer.write(message_bytes)
    await writer.drain()

async def send_chat_to_all(message):
    for player in crew.keys():
        await send_chat_message(player, message)

async def handle_client(reader, writer):
    try:
        joined = False
        player_id = None
        while True:
            code = int.from_bytes(await reader.read(2), "little", signed=False)

            if code == 0: # clean disconnect, i.e. reader read b''
                raise ConnectionError

            if code == 1: # client hello
                writer.write(SERVER_INIT.to_bytes(2, "little", signed=False))
                writer.write(protocol_version.to_bytes(2, "little", signed=False))

            elif code == 2: # client confirmation
                player_id = 0
                while(player_id in crew.keys()):
                    player_id += 1
                crew[player_id] = [writer, (0,0,0)]
                joined = True
                for pid in crew.keys():
                    if pid != player_id:
                        p_writer = crew[pid][0]
                        p_writer.write(SERVER_NEWPLAYER.to_bytes(2, "little", signed=False))
                        p_writer.write(player_id.to_bytes(4, "little", signed=False))
                        await p_writer.drain()
                        writer.write(SERVER_NEWPLAYER.to_bytes(2, "little", signed=False))
                        writer.write(pid.to_bytes(4, "little", signed=False))
                        await writer.drain()
                        writer.write(SERVER_UPDATEPLAYER.to_bytes(2, "little", signed=False))
                        writer.write(pid.to_bytes(4, "little", signed=False))
                        x, y, z = crew[pid][1]
                        writer.write(x.to_bytes(4, "little", signed=True))
                        writer.write(y.to_bytes(4, "little", signed=True))
                        writer.write(z.to_bytes(4, "little", signed=True))
                        await writer.drain()
                await send_chat_to_all("Client has connected")

            elif code == 3: # client position update
                x = int.from_bytes(await reader.read(4), "little", signed=True)
                y = int.from_bytes(await reader.read(4), "little", signed=True)
                z = int.from_bytes(await reader.read(4), "little", signed=True)
                if joined:
                    crew[player_id][1] = (x,y,z)
                    for pid in crew.keys():
                        if pid != player_id:
                            p_writer = crew[pid][0]
                            p_writer.write(SERVER_UPDATEPLAYER.to_bytes(2, "little", signed=False))
                            p_writer.write(player_id.to_bytes(4, "little", signed=False))
                            p_writer.write(x.to_bytes(4, "little", signed=True))
                            p_writer.write(y.to_bytes(4, "little", signed=True))
                            p_writer.write(z.to_bytes(4, "little", signed=True))
                            await p_writer.drain()
            
            elif code == 4: # client chat message
                length = int.from_bytes(await reader.read(4), "little", signed=True)
                message = (await reader.read(length)).decode("utf-8")
                await send_chat_to_all(message)
            
            elif code == 5: # player damaged another
                target_id = int.from_bytes(await reader.read(4), "little", signed=False)
                amount = int.from_bytes(await reader.read(4), "little", signed=True)
                if target_id in crew.keys():
                   p_writer = crew[target_id][0]
                   p_writer.write(SERVER_DAMAGEPLAYER.to_bytes(2, "little", signed=False))
                   p_writer.write(amount.to_bytes(4, "little", signed=True))

            await writer.drain()

    except ConnectionError as e: # client disconnect
        if joined:
            del crew[player_id]
            for pid in crew.keys():
                p_writer = crew[pid][0]
                p_writer.write(SERVER_DELETEPLAYER.to_bytes(2, "little", signed=False))
                p_writer.write(player_id.to_bytes(4, "little", signed=False))
                await p_writer.drain()
                await send_chat_to_all("Client Disconnected.")

async def run_server():
    server = await asyncio.start_server(handle_client, "localhost", 7411)
    async with server:
        await server.serve_forever()

asyncio.run(run_server())