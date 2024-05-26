from flask import Blueprint, jsonify

model2_blueprint = Blueprint('model2', __name__)


@model2_blueprint.route('/', methods=['GET'])
def get_model2():
    return jsonify({'message': 'Model2 endpoint'})
