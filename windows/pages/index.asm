.386
.model flat, stdcall
option casemap:none

.data
PUBLIC index_content
index_content db "<html><head>"
              db "<title>Home Page</title>"
              db "<style>"
              db "body {"
              db "    background-color: #121212;"
              db "    color: #e0e0e0;"
              db "    font-family: Arial, sans-serif;"
              db "    text-align: center;"
              db "    margin: 0;"
              db "    padding: 0;"
              db "}"
              db "h1 {"
              db "    color: #ffffff;"
              db "    margin-top: 50px;"
              db "}"
              db "p {"
              db "    font-size: 16px;"
              db "    margin: 20px;"
              db "}"
              db "a {"
              db "    color: #bb86fc;"
              db "    text-decoration: none;"
              db "    font-weight: bold;"
              db "}"
              db "a:hover {"
              db "    text-decoration: underline;"
              db "}"
              db "</style>"
              db "</head><body>"
              db "<h1>Welcome to the Home Page</h1>"
              db "<p>This is the index page of our Assembly web server.</p>"
              db "<a href='/about'>About Us</a>"
              db "</body></html>", 0

.code

end
