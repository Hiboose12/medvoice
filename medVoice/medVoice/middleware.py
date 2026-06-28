from django.utils.cache import add_never_cache_headers

class NoCacheMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)
        # Disable caching for all responses to prevent back-button access to secured pages
        # We set these manually to be absolutely sure, overriding any defaults
        response['Cache-Control'] = 'no-store, no-cache, must-revalidate, max-age=0, post-check=0, pre-check=0'
        response['Pragma'] = 'no-cache'
        response['Expires'] = '0'
        return response

class LocalDevCSRFExemptMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        origin = request.META.get('HTTP_ORIGIN', '')
        if origin.startswith('http://localhost:') or origin.startswith('http://192.168.39.110:') or origin.startswith('http://192.168.0.147:'):
            setattr(request, '_dont_enforce_csrf_checks', True)
        return self.get_response(request)
