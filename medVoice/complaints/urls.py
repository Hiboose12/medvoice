from django.urls import path
from .views import feed, upload_complaint
from .views import my_complaints,delete_comment
from .views import like_complaint, like_complaint_ajax, add_comment 
from .views import complaint_detail, update_complaint_status, hospital_public_response, patient_mark_resolved, authority_send_warning, edit_complaint, edit_post_ajax, delete_post_ajax


urlpatterns = [
    path("feed/", feed, name="feed"),
    path("complaint/upload/", upload_complaint, name="upload"),
    path("my-complaints/", my_complaints, name="my_complaints"),
    path("like/<int:complaint_id>/", like_complaint, name="like"),
    path("like/<int:complaint_id>/ajax/", like_complaint_ajax, name="like_ajax"),
    path("comment/<int:complaint_id>/", add_comment, name="add_comment"),
    path("comment/delete/<int:comment_id>/", delete_comment, name="delete_comment"),
    path(
        "complaint/<int:complaint_id>/",
        complaint_detail,
        name="complaint_detail"
    ),
    path(
        "complaint/<int:complaint_id>/update-status/",
        update_complaint_status,
        name="update_complaint_status"
    ),
    path(
        "complaint/<int:complaint_id>/respond/",
        hospital_public_response,
        name="hospital_public_response"
    ),
    path(
        "complaint/<int:complaint_id>/resolve/",
        patient_mark_resolved,
        name="patient_mark_resolved"
    ),
    path(
        "complaint/<int:complaint_id>/authority-warning/",
        authority_send_warning,
        name="authority_send_warning"
    ),
    path(
        "complaint/<int:complaint_id>/edit/",
        edit_complaint,
        name="edit_complaint"
    ),
    path(
        "complaint/<int:complaint_id>/edit-ajax/",
        edit_post_ajax,
        name="edit_post_ajax"
    ),
    path(
        "complaint/<int:complaint_id>/delete-ajax/",
        delete_post_ajax,
        name="delete_post_ajax"
    ),
]

