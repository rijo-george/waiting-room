"""Allow running with: python -m waiting_room"""

from .app import WaitingRoomApp

def main():
    WaitingRoomApp().run()

if __name__ == "__main__":
    main()
