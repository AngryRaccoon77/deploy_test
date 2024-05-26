from flask import Blueprint, jsonify

model1_blueprint = Blueprint('model1', __name__)


@model1_blueprint.route('/', methods=['GET'])
def get_model1():
    return jsonify({'message': 'Model1 endpoint'})
