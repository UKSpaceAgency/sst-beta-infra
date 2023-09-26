import json
import os
import requests
import sys


user_id_map = {
    "user1": "U051GF3CFAP"
}


def get_title_emoji(number_of_envs):
    if number_of_envs > 5:
        return ":triggered_parrot:"
    elif number_of_envs >= 3:
        return ":alert:"
    else:
        return ":rotating_light:"


def slack(payload, webhook_url):

    source_provider = payload.get("source_provider")
    source_type = payload.get("source_type")
    env = payload.get("env")

    title = (
        f":rotating_light: {source_provider} {source_type} alarm - {env}")
    slack_data = {
        "text": title,
        "username": f"Ingestion Officer",
        "icon_emoji": ":female-police-officer:",
        "blocks": [
                      {
                          "type": "header",
                          "text": {
                              "type": "plain_text",
                              "text": title
                          }
                      }]
    }
    byte_length = str(sys.getsizeof(slack_data))
    requests.post(webhook_url, data=json.dumps(slack_data),
                  headers={'Content-Type': "application/json", 'Content-Length': byte_length})


def lambda_handler(event, context):
    # Parse the payload as JSON
    print(event)
    webhook_url = os.environ['SLACK_WEBHOOK_URL']
    slack(event, webhook_url)

    return {
        "statusCode": 200,
        "body": f"Everything was fine"
    }

