from django.urls import path
from django.views.generic import RedirectView
from .views import support, contact_support, chat_home, chat_room, send_message, search_users, start_chat, get_messages, start_complaint_chat, get_complaint_chat_info, delete_message
from .views import patient_chat_view, patient_chat_room, hospital_chat_view, hospital_chat_room, patient_start_chat, hospital_start_chat
from .views import authority_chat_view, authority_chat_room

urlpatterns = [
    path("support/", support, name="support"),
    path("social/support/", RedirectView.as_view(pattern_name="support"), name="support_legacy"),
    path("contact-support/", contact_support, name="contact_support"),
    
    # Chat Routes
    path("chat/", chat_home, name="chat_home"),
    path("chat/search/", search_users, name="search_users"), # API
    path("chat/start/<int:user_id>/", start_chat, name="start_chat"),
    path("patient/chat/", patient_chat_view, name="patient_chat_home"),
    path("patient/chat/<int:conversation_id>/", patient_chat_room, name="patient_chat_room"),
    path("patient/chat/start/<int:user_id>/", patient_start_chat, name="patient_chat_start"),
    
    path("hospital/chat/", hospital_chat_view, name="hospital_chat_home"),
    path("hospital/chat/<int:conversation_id>/", hospital_chat_room, name="hospital_chat_room"),
    path("hospital/chat/start/<int:user_id>/", hospital_start_chat, name="hospital_chat_start"),
    
    path("authority/chat/", authority_chat_view, name="authority_chat_home"),
    path("authority/chat/<int:conversation_id>/", authority_chat_room, name="authority_chat_room"),
    
    path("chat/start-complaint/<int:complaint_id>/", start_complaint_chat, name="start_complaint_chat"),
    path("chat/complaint-info/<int:complaint_id>/", get_complaint_chat_info, name="get_complaint_chat_info"), # API for Modal
    path("chat/<int:conversation_id>/", chat_room, name="chat_room"),
    path("chat/<int:conversation_id>/send/", send_message, name="send_message"),
    path("chat/<int:conversation_id>/messages/", get_messages, name="get_messages"), # API
    path("chat/message/<int:message_id>/delete/", delete_message, name="delete_message"),
]
