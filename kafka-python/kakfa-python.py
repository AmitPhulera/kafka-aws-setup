from kafka.client import SimpleClient
from .const import KAFKA_BROKERS, GENERIC_KAFKA_CLIENT_ID, ALL_TOPICS


def get_kakfa_client():
    return SimpleClient(
        hosts=KAFKA_BROKERS,
        client_id=GENERIC_KAFKA_CLIENT_ID,
        timeout=30
    )


def create_kafka_topics():
    client = get_kakfa_client()
    for topic in ALL_TOPICS:
        if client.has_metadata_for_topic(topic):
            status = "already exists"
        else:
            client.ensure_topic_exists(topic, timeout=10)
            status = "created"
        print("topic {}: {}".format(status, topic))
