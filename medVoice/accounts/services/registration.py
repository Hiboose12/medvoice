import re

from django.conf import settings


def _normalize_pincode(pincode):
    if not pincode:
        return ""
    return "".join(ch for ch in str(pincode) if ch.isdigit())


def validate_pincode(pincode):
    """
    Validate Indian pincode using regex pattern.
    Indian pincodes are 6-digit numbers starting with 1-9.
    No external API call needed.
    """
    normalized = _normalize_pincode(pincode)
    
    # Basic format validation - Indian pincodes are 6 digits
    if len(normalized) != 6:
        return {"is_valid": False, "district": None, "state": None}
    
    # Validate format - first digit cannot be 0
    if not normalized.isdigit() or normalized[0] == '0':
        return {"is_valid": False, "district": None, "state": None}
    
    # If pincode format is valid, return success
    # District and state can be filled by user manually
    return {"is_valid": True, "district": None, "state": None}


def _normalize_govt_id_number(govt_id_number):
    if govt_id_number is None:
        return ""
    return str(govt_id_number).strip().replace(" ", "").replace("-", "")


def validate_government_id(govt_id_type, govt_id_number):
    normalized = _normalize_govt_id_number(govt_id_number)

    api_url = getattr(settings, "GOVT_ID_API_URL", None)
    if api_url:
        timeout = getattr(settings, "GOVT_ID_API_TIMEOUT", 5)
        payload = json.dumps({
            "id_type": govt_id_type,
            "id_number": normalized,
        }).encode("utf-8")
        req = urllib.request.Request(
            api_url,
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(req, timeout=timeout) as response:
                body = response.read().decode("utf-8")
            result = json.loads(body)
            return bool(result.get("valid"))
        except Exception:
            return False

    if govt_id_type == "aadhaar":
        return bool(re.fullmatch(r"\d{12}", normalized))

    if govt_id_type == "pan":
        upper = normalized.upper()
        return bool(re.fullmatch(r"[A-Z]{5}\d{4}[A-Z]", upper))

    if govt_id_type == "voter_id":
        upper = normalized.upper()
        return bool(re.fullmatch(r"[A-Z]{3}\d{7}", upper))

    return False
