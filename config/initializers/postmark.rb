
# postmark initializing constants:

PUSHER_APP_ID = '41800'
PUSHER_API_KEY = '11a1d71f5a5743153dda'
PUSHER_SECRET_KEY = '861b97d91d15edbae270'
PUSHER_CHANNEL_NAME = 'game-room'

# Game events, triggered at the client-side by postmark triggers:
PUSHER_EVENT_WAIT = 'client-wait-for-opponent'
PUSHER_EVENT_START = 'client-start-to-play'
PUSHER_EVENT_INTERRUPTED = 'client-game-room-closed'
PUSHER_EVENT_ALERT = 'client-alert'

# New user will be rejected and notified with 'room is full' message,  if user sessions count reached this value:
PUSHER_MAX_GAME_CONNECTION = 2

