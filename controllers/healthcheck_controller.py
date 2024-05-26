from flask import Blueprint, jsonify

healthcheck_blueprint = Blueprint('healthcheck', __name__)


@healthcheck_blueprint.route('/', methods=['GET'])
def healthcheck():
    return jsonify({'status': 'ok'})
