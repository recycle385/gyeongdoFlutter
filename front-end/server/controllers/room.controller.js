const { rooms, socketToRoom, socketToSession } = require('../utils/store');
const { v4: uuidv4 } = require('uuid');

const joinRoom = (io, socket, { roomId, sessionId, nickname }) => {
    // 1. 방 존재 확인
    if (!rooms.has(roomId)) {
        // 방이 없으면 임시로 생성 (테스트 편의성 위해)
        // 실제로는 CreateRoom을 통해 생성되어야 함
        console.log(`[Room] Creating new room: ${roomId}`);
        rooms.set(roomId, {
            roomId,
            hostId: sessionId, // 첫 번째 입장 유저를 호스트로
            players: new Map(),
            gameState: {
                status: 'waiting',
                remainingTime: 1800, // 30분 기본
                winner: null
            }
        });
    }

    const room = rooms.get(roomId);

    // 2. 플레이어 생성 또는 갱신
    let player = room.players.get(sessionId);
    if (!player) {
        player = {
            sessionId,
            nickname: nickname || `User-${sessionId.substring(0, 4)}`,
            team: 'unassigned',
            status: 'alive',
            socketId: socket.id
        };
        // 첫 번째 유저는 호스트
        if (room.players.size === 0) {
            room.hostId = sessionId;
        }
        room.players.set(sessionId, player);
    } else {
        // 재접속 처리
        player.socketId = socket.id;
        player.status = 'alive'; // 연결 복구
    }

    // 3. 매핑 저장
    socketToRoom.set(socket.id, roomId);
    socketToSession.set(socket.id, sessionId);

    // 4. Socket Join
    socket.join(roomId);

    // 5. 현재 상태 전송
    // 나에게만: 내 정보
    socket.emit('room:joined', {
        roomId,
        myTeam: player.team,
        isHost: room.hostId === sessionId
    });

    // 방 전체: 플레이어 목록 업데이트
    broadcastPlayerList(io, roomId);
};

const assignRole = (io, socket, { targetSessionId, team }) => {
    const roomId = socketToRoom.get(socket.id);
    if (!roomId) return;

    const room = rooms.get(roomId);
    if (!room) return;

    // 권한 확인 (호스트만)
    const requesterSession = socketToSession.get(socket.id);
    if (room.hostId !== requesterSession) {
        socket.emit('error', { message: 'Only host can assign roles' });
        return;
    }

    const targetPlayer = room.players.get(targetSessionId);
    if (targetPlayer) {
        targetPlayer.team = team;
        broadcastPlayerList(io, roomId);

        // 대상자에게 알림
        const targetSocket = io.sockets.sockets.get(targetPlayer.socketId);
        if (targetSocket) {
            targetSocket.emit('role:assigned', { team });
        }
    }
};

const broadcastPlayerList = (io, roomId) => {
    const room = rooms.get(roomId);
    if (!room) return;

    const playerList = Array.from(room.players.values()).map(p => ({
        sessionId: p.sessionId,
        nickname: p.nickname,
        team: p.team,
        status: p.status,
        isHost: room.hostId === p.sessionId
    }));

    io.to(roomId).emit('players:updated', playerList);
};

module.exports = {
    joinRoom,
    assignRole
};
