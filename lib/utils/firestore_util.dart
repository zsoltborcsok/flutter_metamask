String escape(String documentId) {
  return documentId.replaceAll('/', '%2F');
}

String unEscape(String documentId) {
  return documentId.replaceAll('%2F', '/');
}
