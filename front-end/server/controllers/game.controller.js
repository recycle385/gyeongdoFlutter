const { rooms, socketToRoom, socketToSession } = require('../utils/store');

const startGame = (io, socket) => {
    const roomId = socketToRoom.get(socket.id);
    if (!roomId) return;

    const room = rooms.get(roomId);
    if (!room) return;

    // 권한 확인
    const requesterSession = socketToSession.get(socket.id);
    if (room.hostId !== requesterSession) return;

    // 게임 상태 변경
    room.gameState.status = 'playing';
    room.gameState.startTime = Date.now();

    // 타이머 시작 (간단한 구현)
    if (room.timerInterval) clearInterval(room.timerInterval);

    room.timerInterval = setInterval(() => {
        if (room.gameState.remainingTime > 0) {
            room.gameState.remainingTime--;

            // 1분마다 또는 중요 시점에만 브로드캐스트 하는 것이 좋으나, MVP는 매초 전송 고려
            // 여기서는 5초마다 동기화한다고 가정하거나, 클라이언트가 자체 계산
            // MVP: 매초 전송 (최적화 필요)
            io.to(roomId).emit('timer:update', {
                remainingTime: room.gameState.remainingTime,
                status: room.gameState.status
            });
        } else {
            endGame(io, roomId, 'time_up');
        }
    }, 1000);

    // 시작 이벤트 전송 (플레이어 목록, 초기 상태 등)
    const players = Array.from(room.players.values());
    io.to(roomId).emit('game:started', {
        gameState: room.gameState,
        players: players
    });
};

const updateLocation = (io, socket, { lat, lng }) => {
    const roomId = socketToRoom.get(socket.id);
    const sessionId = socketToSession.get(socket.id);
    if (!roomId || !sessionId) return;

    const room = rooms.get(roomId);
    const player = room.players.get(sessionId);

    if (player) {
        player.location = { lat, lng };
        // 위치 정보 브로드캐스트 (내 위치 제외하거나 전체 전송)
        // MVP: 전체 플레이어 위치 정보를 주기적으로 모아서 보내거나, 개별 전송
        // 여기서는 개별 전송을 Relay
        // socket.to(roomId).emit('player:moved', { sessionId, lat, lng });
    }
};

const requestArrest = (io, socket, { thiefId }) => {
    const roomId = socketToRoom.get(socket.id);
    const policeId = socketToSession.get(socket.id);

    // 도둑에게 알림
    const room = rooms.get(roomId);
    const thief = room.players.get(thiefId);

    if (thief && thief.socketId) {
        io.to(thief.socketId).emit('arrest:requested', {
            policeId,
            timeLimit: 5
        });
    }
};

const respondArrest = (io, socket, { policeId, accept }) => {
    const roomId = socketToRoom.get(socket.id);
    const thiefId = socketToSession.get(socket.id);

    if (accept) {
        // 체포 처리
        const room = rooms.get(roomId);
        const thief = room.players.get(thiefId);
        thief.status = 'dead';

        io.to(roomId).emit('player:arrested', {
            thiefId,
            policeId
        });

        checkGameOver(io, roomId);
    }
};

const triggerJailbreak = (io, socket) => {
    const roomId = socketToRoom.get(socket.id);
    const thiefId = socketToSession.get(socket.id);

    io.to(roomId).emit('jailbreak:triggered', {
        thiefId,
        duration: 3
    });

    // 3초 후 성공 처리 (서버에서 거리 체크해야 하지만 MVP는 무조건 성공)
    setTimeout(() => {
        const room = rooms.get(roomId);
        if (!room) return;

        // 감옥에 있는 모든 도둑 해방 (또는 로직에 따라 다름)
        const freedThieves = [];
        for (let p of room.players.values()) {
            if (p.team === 'thief' && p.status === 'dead') {
                p.status = 'alive';
                freedThieves.push(p.sessionId);
            }
        }

        io.to(roomId).emit('player:freed', {
            freedThieves
        });
    }, 3000);
};

const checkGameOver = (io, roomId) => {
    const room = rooms.get(roomId);
    let aliveThieves = 0;
    for (let p of room.players.values()) {
        if (p.team === 'thief' && p.status === 'alive') {
            aliveThieves++;
        }
    }

    if (aliveThieves === 0) {
        endGame(io, roomId, 'police_win');
    }
};

const endGame = (io, roomId, reason) => {
    const room = rooms.get(roomId);
    if (!room) return;

    if (room.timerInterval) clearInterval(room.timerInterval);
    room.gameState.status = 'ended';
    room.gameState.winner = reason === 'police_win' ? 'police' : 'thief';

    io.to(roomId).emit('game:ended', {
        finalState: room.gameState,
        winner: room.gameState.winner
    });
};

module.exports = {
    startGame,
    updateLocation,
    requestArrest,
    respondArrest,
    triggerJailbreak
};
