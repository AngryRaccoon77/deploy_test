from flask import Flask
from controllers.model1_controller import model1_blueprint
from controllers.model2_controller import model2_blueprint
from controllers.healthcheck_controller import healthcheck_blueprint

app = Flask(__name__)

app.register_blueprint(model1_blueprint, url_prefix='/api/model1')
app.register_blueprint(model2_blueprint, url_prefix='/api/model2')
app.register_blueprint(healthcheck_blueprint, url_prefix='/')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
