require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const roomController = require('./controllers/room.controller');
const gameController = require('./controllers/game.controller');
const { socketToRoom, socketToSession, rooms } = require('./utils/store');

const app = express();
app.use(cors());
app.use(express.json());

const server = http.createServer(app);
const io = new Server(server, {
    cors: {
        origin: "*", // Flutter 앱 허용
        methods: ["GET", "POST"]
    }
});

io.on('connection', (socket) => {
    console.log(`[Socket] Connected: ${socket.id}`);

    // Room Events
    socket.on('room:join', (data) => roomController.joinRoom(io, socket, data));
    socket.on('role:assign', (data) => roomController.assignRole(io, socket, data));

    // Game Events
    socket.on('game:start', () => gameController.startGame(io, socket));
    socket.on('location:update', (data) => gameController.updateLocation(io, socket, data));
    socket.on('arrest:request', (data) => gameController.requestArrest(io, socket, data));
    socket.on('arrest:respond', (data) => gameController.respondArrest(io, socket, data));
    socket.on('jailbreak:trigger', () => gameController.triggerJailbreak(io, socket));

    socket.on('disconnect', () => {
        console.log(`[Socket] Disconnected: ${socket.id}`);
        // 간단한 연결 종료 처리 (재접속 고려하여 플레이어 데이터는 유지)
        // 실제로는 타임아웃 후 제거 등의 로직 필요
    });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
    console.log(`SERVER RUNNING ON PORT ${PORT}`);
});
