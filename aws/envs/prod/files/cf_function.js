function handler(event) {
    var request = event.request;

    var response = {
        statusCode: 301,
        statusDescription: 'Moved Permanently',
        headers: {
            'location': { value: 'https://www.monitor-space-hazards.service.gov.uk'+event.request.uri }
        }
    };
    return response;

}