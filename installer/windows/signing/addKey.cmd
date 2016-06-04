openssl aes-256-cbc -k %ENCRYPTION_SECRET% -in authenticode-signing-cert.p12.enc -out authenticode-signing-cert.p12 -d -a
certutil -p %KEY_PASSWORD% -user -importpfx authenticode-signing-cert.p12 NoRoot
