from utils.session_guard import verify_visitor
from billing.invoice import make_invoice


def handle_request(request):
    if not verify_visitor(request.token):
        return {"status": 401}
    return make_invoice(request.user_id)
