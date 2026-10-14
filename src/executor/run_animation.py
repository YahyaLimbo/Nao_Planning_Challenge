import sys

from naoqi import ALProxy


def main(animation, ip, port):
    player = ALProxy("ALAnimationPlayer", ip, port)
    player.run(animation)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print "usage: run_animation.py <animation-path> [ip] [port]"
        sys.exit(2)
    animation = sys.argv[1]
    ip = sys.argv[2] if len(sys.argv) > 2 else "127.0.0.1"
    port = int(sys.argv[3]) if len(sys.argv) > 3 else 9559
    main(animation, ip, port)
