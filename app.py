import os

import boto3
import dotenv
import flask

dotenv.load_dotenv()

AUTH_SECRET = os.environ["AUTH_SECRET"]

app = flask.Flask(__name__, template_folder=".")

ec2 = boto3.resource("ec2")


def get_ec2_info():
    all_instances = [
        inst
        for inst in ec2.instances.all()  # type: ignore
        if any(
            tag["Key"] == "corona-updown" and tag["Value"] == "true"
            for tag in inst.tags
        )
    ]
    if len(all_instances) != 1:
        return {
            "error": f"There appear to be {len(all_instances)} EC2 instances running that are tagged as a Minecraft server, which is unexpected since there should be exactly one. Please use the Amazon Web Services console or CLI to manage the server, or contact the server administrator."
        }
    (instance,) = all_instances
    state = instance.state["Name"]
    # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-lifecycle.html
    actions = []
    if state == "running":
        actions = ["stop", "reboot"]
    if state == "stopped":
        actions = ["start"]
    return {
        "error": None,
        "ec2": instance,
        "state": state,
        "ip": instance.public_ip_address,
        "actions": actions,
        "action_styles": {
            "start": "btn-success",
            "stop": "btn-danger",
            "reboot": "btn-warning",
        },
    }


@app.before_request
def require_login():
    token = flask.request.cookies.get("auth-token")
    if token != AUTH_SECRET:
        return flask.send_from_directory(".", "auth.html")


@app.route("/")
def index():
    return flask.render_template(
        "index.html",
        info=get_ec2_info(),
    )


@app.route("/api/v1/<action>", methods=["POST"])
def reboot(action):
    if action not in {"start", "stop", "reboot"}:
        return f"Unsupported action ${action}", 404
    info: any = get_ec2_info()  # type: ignore
    if info["error"]:
        return info["error"], 502
    try:
        if action == "start":
            info["ec2"].start()
        elif action == "stop":
            info["ec2"].stop()
        elif action == "reboot":
            info["ec2"].reboot()
        else:
            raise Exception("internal error")
    except Exception as e:
        return str(e), 500
    return "", 204
