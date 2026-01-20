// In-memory storage for MVP
// Production environment should use Redis

/**
 * Room Structure:
 * {
 *   roomId: string,
 *   hostId: string,
 *   gameDuration: number,
 *   polygons: [], // Coordinates for safe area
 *   jail: { lat, lng, radius },
 *   players: Map<string, Player>, // sessionId -> Player
 *   gameState: {
 *     status: 'waiting' | 'playing' | 'ended',
 *     startTime: number | null,
 *     remainingTime: number,
 *     winner: null
 *   }
 * }
 */

/**
 * Player Structure:
 * {
 *   sessionId: string,
 *   nickname: string,
 *   team: 'police' | 'thief' | 'unassigned',
 *   status: 'alive' | 'dead' | 'spectator',
 *   socketId: string,
 *   location: { lat, lng }
 * }
 */

const rooms = new Map(); // roomId -> Room
const socketToRoom = new Map(); // socketId -> roomId
const socketToSession = new Map(); // socketId -> sessionId

module.exports = {
    rooms,
    socketToRoom,
    socketToSession
};
