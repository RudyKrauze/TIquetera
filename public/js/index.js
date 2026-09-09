      // ============ VALIDACIONES EN TIEMPO REAL ============

      // Validación de email
      const emailField = document.getElementById("email");
      const emailError = document.getElementById("emailError");

      function validateEmail(email) {
        if (!email) return false;
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
      }

      emailField.addEventListener("blur", function () {
        const email = this.value.trim();
        if (!email || !validateEmail(email)) {
          this.classList.add("invalid");
          this.classList.remove("valid");
          emailError.classList.add("show");
        } else {
          this.classList.remove("invalid");
          this.classList.add("valid");
          emailError.classList.remove("show");
        }
      });

      emailField.addEventListener("input", function () {
        if (this.classList.contains("invalid")) {
          const email = this.value.trim();
          if (!email || validateEmail(email)) {
            this.classList.remove("invalid");
            emailError.classList.remove("show");
            if (email) this.classList.add("valid");
          }
        }
      });

      // Validación de nombre
      const nameField = document.getElementById("name");
      const nameError = document.getElementById("nameError");

      nameField.addEventListener("blur", function () {
        if (!this.value.trim()) {
          this.classList.add("invalid");
          this.classList.remove("valid");
          nameError.classList.add("show");
        } else {
          this.classList.remove("invalid");
          this.classList.add("valid");
          nameError.classList.remove("show");
        }
      });

      nameField.addEventListener("input", function () {
        if (this.value.trim()) {
          this.classList.remove("invalid");
          this.classList.add("valid");
          nameError.classList.remove("show");
        }
      });

      // ============ CONTADORES DE CARACTERES MEJORADOS ============

      // Contador para título
      const titleField = document.getElementById("title");
      const titleCharCount = document.getElementById("titleCharCount");
      const titleProgress = document.getElementById("titleProgress");
      const titleError = document.getElementById("titleError");

      titleField.addEventListener("input", function () {
        const length = this.value.length;
        const maxLength = 200;
        const percentage = (length / maxLength) * 100;

        titleCharCount.textContent = length;
        titleProgress.style.width = percentage + "%";

        // Cambiar colores según proximidad al límite
        titleProgress.classList.remove("warning", "danger");
        if (percentage > 90) {
          titleProgress.classList.add("danger");
          titleCharCount.style.color = "#dc3545";
        } else if (percentage > 75) {
          titleProgress.classList.add("warning");
          titleCharCount.style.color = "#ffc107";
        } else {
          titleCharCount.style.color = "#6c757d";
        }

        // Validar campo
        if (this.value.trim()) {
          this.classList.remove("invalid");
          this.classList.add("valid");
          titleError.classList.remove("show");
        }
      });

      titleField.addEventListener("blur", function () {
        if (!this.value.trim()) {
          this.classList.add("invalid");
          this.classList.remove("valid");
          titleError.classList.add("show");
        }
      });

      // Contador para descripción
      const descriptionField = document.getElementById("description");
      const charCount = document.getElementById("charCount");
      const descProgress = document.getElementById("descProgress");
      const descriptionError = document.getElementById("descriptionError");

      descriptionField.addEventListener("input", function () {
        const length = this.value.length;
        const maxLength = 2000;
        const percentage = (length / maxLength) * 100;

        charCount.textContent = length;
        descProgress.style.width = percentage + "%";

        // Cambiar colores según proximidad al límite
        descProgress.classList.remove("warning", "danger");
        if (percentage > 95) {
          descProgress.classList.add("danger");
          charCount.style.color = "#dc3545";
        } else if (percentage > 85) {
          descProgress.classList.add("warning");
          charCount.style.color = "#ffc107";
        } else {
          charCount.style.color = "#6c757d";
        }

        // Validar campo
        if (this.value.trim()) {
          this.classList.remove("invalid");
          this.classList.add("valid");
          descriptionError.classList.remove("show");
        }
      });

      descriptionField.addEventListener("blur", function () {
        if (!this.value.trim()) {
          this.classList.add("invalid");
          this.classList.remove("valid");
          descriptionError.classList.add("show");
        }
      });

      // Permitir buscar ticket al presionar Enter
      const trackingSearchInput = document.getElementById(
        "trackingSearchInput"
      );
      if (trackingSearchInput) {
        trackingSearchInput.addEventListener("keypress", function (e) {
          if (e.key === "Enter") {
            e.preventDefault();
            searchTicketPublic();
          }
        });
      }

      // ============ MANEJO DE ARCHIVOS ============
      let selectedFiles = [];

      const fileInput = document.getElementById('ticketAttachments');
      const attachmentsPreview = document.getElementById('attachmentsPreview');
      const attachmentsError = document.getElementById('attachmentsError');
      const MAX_FILES = 3;
      const MAX_SIZE_MB = 20;

      fileInput.addEventListener('change', function(e) {
        const files = Array.from(e.target.files);
        
        // Limpiar error previo
        attachmentsError.classList.remove('show');

        // Validar cantidad
        if (selectedFiles.length + files.length > MAX_FILES) {
           attachmentsError.textContent = `Máximo ${MAX_FILES} archivos permitidos`;
           attachmentsError.classList.add('show');
           return;
        }

        // Procesar archivos
        files.forEach(file => {
          // Validar tipo (MIME o extensión para soporte móvil)
          const validTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/heic', 'image/heif'];
          const validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic', '.heif', '.avif'];
          
          const isImageMime = file.type.startsWith('image/');
          const hasValidExt = validExtensions.some(ext => file.name.toLowerCase().endsWith(ext));

          if (!isImageMime && !hasValidExt) {
            attachmentsError.textContent = 'Solo se permiten imágenes (JPG, PNG, WebP, HEIC)';
            attachmentsError.classList.add('show');
            return;
          }

          // Verificar duplicados (por nombre y tamaño simple)
          if (selectedFiles.some(f => f.name === file.name && f.size === file.size)) {
            return;
          }

          selectedFiles.push(file);
        });

        // Validar tamaño total
        const totalSize = selectedFiles.reduce((acc, file) => acc + file.size, 0);
        if (totalSize > MAX_SIZE_MB * 1024 * 1024) {
           attachmentsError.textContent = `El tamaño total excede ${MAX_SIZE_MB}MB`;
           attachmentsError.classList.add('show');
           // Revertir último agregado si es necesario, o dejar que el usuario borre
        }

        renderPreviews();
        
        // Reset input para permitir seleccionar el mismo archivo si se borró y se quiere subir de nuevo
        fileInput.value = ''; 
      });

      function renderPreviews() {
        attachmentsPreview.innerHTML = '';
        selectedFiles.forEach((file, index) => {
          const div = document.createElement('div');
          div.className = 'attachment-thumb';
          
          const img = document.createElement('img');
          img.src = URL.createObjectURL(file);
          
          const btn = document.createElement('button');
          btn.className = 'remove-attachment';
          btn.innerHTML = '×';
          btn.onclick = () => removeAttachment(index);
          
          div.appendChild(img);
          div.appendChild(btn);
          attachmentsPreview.appendChild(div);
        });
      }

      function removeAttachment(index) {
        selectedFiles.splice(index, 1);
        renderPreviews();
        
        // Re-validar tamaño total por si había error
        const totalSize = selectedFiles.reduce((acc, file) => acc + file.size, 0);
        if (totalSize <= MAX_SIZE_MB * 1024 * 1024) {
           attachmentsError.classList.remove('show');
        }
      }

      document
        .getElementById("ticketForm")
        .addEventListener("submit", async function (e) {
          e.preventDefault();

          // Validar todos los campos antes de enviar
          let isValid = true;

          // Validar nombre
          if (!nameField.value.trim()) {
            nameField.classList.add("invalid", "shake");
            nameError.classList.add("show");
            isValid = false;
            setTimeout(() => nameField.classList.remove("shake"), 500);
          }

          // Validar email
          if (!emailField.value.trim() || !validateEmail(emailField.value.trim())) {
            emailField.classList.add("invalid", "shake");
            emailError.classList.add("show");
            isValid = false;
            setTimeout(() => emailField.classList.remove("shake"), 500);
          }

          // Validar área afectada
          const affectedAreaField = document.getElementById("affected_area");
          const affectedAreaError =
            document.getElementById("affectedAreaError");
          if (!affectedAreaField.value.trim()) {
            affectedAreaField.classList.add("invalid", "shake");
            affectedAreaError.classList.add("show");
            isValid = false;
            setTimeout(() => affectedAreaField.classList.remove("shake"), 500);
          } else {
            affectedAreaField.classList.remove("invalid");
            affectedAreaError.classList.remove("show");
          }

          // Validar área de asignación
          const departmentField = document.getElementById("department");
          const departmentError = document.getElementById("departmentError");
          if (!departmentField.value) {
            departmentField.classList.add("invalid", "shake");
            departmentError.classList.add("show");
            isValid = false;
            setTimeout(() => departmentField.classList.remove("shake"), 500);
          } else {
            departmentField.classList.remove("invalid");
            departmentError.classList.remove("show");
          }

          // Validar sede
          const sedeField = document.getElementById("sede");
          const sedeError = document.getElementById("sedeError");
          if (!sedeField.value) {
            sedeField.classList.add("invalid", "shake");
            sedeError.classList.add("show");
            isValid = false;
            setTimeout(() => sedeField.classList.remove("shake"), 500);
          } else {
            sedeField.classList.remove("invalid");
            sedeError.classList.remove("show");
          }

          // Validar título
          if (!titleField.value.trim()) {
            titleField.classList.add("invalid", "shake");
            titleError.classList.add("show");
            isValid = false;
            setTimeout(() => titleField.classList.remove("shake"), 500);
          }

          // Validar descripción
          if (!descriptionField.value.trim()) {
            descriptionField.classList.add("invalid", "shake");
            descriptionError.classList.add("show");
            isValid = false;
            setTimeout(() => descriptionField.classList.remove("shake"), 500);
          }
          
          // Validar archivos (tamaño)
          const totalSize = selectedFiles.reduce((acc, file) => acc + file.size, 0);
          if (totalSize > MAX_SIZE_MB * 1024 * 1024) {
             attachmentsError.textContent = `El tamaño total excede ${MAX_SIZE_MB}MB`;
             attachmentsError.classList.add('show');
             isValid = false;
          }

          if (!isValid) {
            const errorMessage = document.getElementById("errorMessage");
            errorMessage.textContent =
              "Por favor completa todos los campos requeridos correctamente";
            errorMessage.style.display = "block";
            return;
          }

          // Preparar FormData
          const formData = new FormData();
          formData.append('name', nameField.value.trim());
          if (emailField.value.trim()) formData.append('email', emailField.value.trim());
          formData.append('affected_area', affectedAreaField.value.trim());
          formData.append('sede', sedeField.value);
          formData.append('department', departmentField.value);
          formData.append('title', titleField.value.trim());
          formData.append('description', descriptionField.value.trim());
          
          // Adjuntar archivos
          selectedFiles.forEach(file => {
            formData.append('attachments', file);
          });

          const submitBtn = this.querySelector(".btn");
          const errorMessage = document.getElementById("errorMessage");

          // Hide error message
          errorMessage.style.display = "none";

          // Show loading state
          submitBtn.textContent = "⏳ Creando ticket...";
          submitBtn.disabled = true;
          submitBtn.classList.add("btn-loading");

          try {
            // Nota: Al enviar FormData, NO se debe establecer Content-Type header manualmente
            // fetch lo establece automáticamente con el boundary correcto
            const response = await fetch("/api/tickets", {
              method: "POST",
              body: formData,
            });

            const result = await response.json();

            if (response.ok) {
              // Show tracking modal instead of success message
              showTrackingModal(
                result.tracking_id ||
                  `TKT-${String(result.id).padStart(5, "0")}`
              );

              // Reset form y contadores
              this.reset();
              selectedFiles = []; // Limpiar archivos seleccionados
              renderPreviews();
              
              charCount.textContent = "0";
              titleCharCount.textContent = "0";
              descProgress.style.width = "0%";
              titleProgress.style.width = "0%";
              descProgress.classList.remove("warning", "danger");
              titleProgress.classList.remove("warning", "danger");

              // Limpiar clases de validación
              nameField.classList.remove("valid", "invalid");
              emailField.classList.remove("valid", "invalid");
              document
                .getElementById("affected_area")
                .classList.remove("valid", "invalid");
              document
                .getElementById("sede")
                .classList.remove("valid", "invalid");
              document
                .getElementById("department")
                .classList.remove("valid", "invalid");
              titleField.classList.remove("valid", "invalid");
              descriptionField.classList.remove("valid", "invalid");
            } else {
              errorMessage.textContent =
                result.error || "Error al crear el ticket";
              errorMessage.style.display = "block";
            }
          } catch (error) {

            errorMessage.textContent =
              "Error de conexión. Por favor, intenta de nuevo.";
            errorMessage.style.display = "block";
          } finally {
            // Reset button
            submitBtn.textContent = "🚀 Crear Ticket";
            submitBtn.disabled = false;
            submitBtn.classList.remove("btn-loading");
          }
        });


      // Modal Functions
      function openLoginModal() {
        document.getElementById("loginModalTitle").textContent =
          "🔐 Iniciar Sesión";
        document.getElementById("loginModal").style.display = "flex";
      }

      function searchTicketPublic() {
        const trackingInput = document.getElementById("trackingSearchInput");
        const trackingId = trackingInput.value.trim();

        if (trackingId) {
          window.location.href = `/track/${encodeURIComponent(trackingId)}`;
        } else {
          // Resaltar el campo si está vacío
          trackingInput.style.borderColor = "#dc3545";
          trackingInput.focus();
          setTimeout(() => {
            trackingInput.style.borderColor = "";
          }, 2000);
        }
      }

      function closeLoginModal() {
        document.getElementById("loginModal").style.display = "none";
        document.getElementById("loginError").style.display = "none";
        document.getElementById("loginForm").reset();
      }

      function togglePasswordVisibility() {
        const passwordInput = document.getElementById("loginPassword");
        const toggle = event.target;
        if (passwordInput.type === "password") {
          passwordInput.type = "text";
          toggle.textContent = "🙈";
        } else {
          passwordInput.type = "password";
          toggle.textContent = "👁️";
        }
      }

      // Login Form Handler
      document
        .getElementById("loginForm")
        .addEventListener("submit", async function (e) {
          e.preventDefault();

          const email = document.getElementById("loginEmail").value;
          const password = document.getElementById("loginPassword").value;
          const errorDiv = document.getElementById("loginError");
          const submitBtn = this.querySelector(".btn");

          errorDiv.style.display = "none";
          submitBtn.textContent = "⏳ Verificando...";
          submitBtn.disabled = true;

          try {
            const response = await fetch("/api/login", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              credentials: "include",
              body: JSON.stringify({ email, password }),
            });

            let data = {};
            try {
              data = await response.json();
            } catch (_) {
              const text = await response.text().catch(() => "");
              data = { error: text };
            }

            if (response.ok) {
              // Redirección automática por rol
              const role = (data.user && data.user.role) || "";

              // Mapeo completo de roles a rutas
              const roleToRoute = {
                administrador: "/administrador",
                gerencia: "/gerencia",
                support: "/support",
                rrhh: "/rrhh",
                mantenimiento: "/mantenimiento",
                compras: "/compras",
                facturacion: "/facturacion",
                contact: "/contact",
              };

              const target = roleToRoute[role] || "/";

              window.location.href = target;
            } else {
              if (response.status === 429) {
                errorDiv.textContent =
                  data.error ||
                  "Demasiados intentos. Por favor espera unos minutos antes de volver a intentar.";
              } else {
                errorDiv.textContent = data.error || "Error al iniciar sesión";
              }
              errorDiv.style.display = "block";
            }
          } catch (error) {
            errorDiv.textContent =
              "Error de conexión. Por favor, intenta de nuevo.";
            errorDiv.style.display = "block";
          } finally {
            submitBtn.textContent = "Iniciar Sesión";
            submitBtn.disabled = false;
          }
        });

      // Tracking Modal Functions
      let currentTrackingId = ""; // Variable global para almacenar el tracking ID actual
      let copyTooltipFadeTimeout;
      let copyTooltipHideTimeout;

      function showTrackingModal(trackingId) {
        currentTrackingId = trackingId; // Guardar para uso posterior
        document.getElementById("trackingNumber").textContent = trackingId;
        document.getElementById("trackingModal").style.display = "flex";
      }

      function closeTrackingModal() {
        document.getElementById("trackingModal").style.display = "none";
      }

      function copyTrackingNumber() {
        const trackingNumber =
          document.getElementById("trackingNumber").textContent;

        // Función para mostrar feedback visual
        function showCopyFeedback() {
          const btn = document.querySelector(".copy-btn");
          const tooltip = document.getElementById("copyTooltip");
          const originalText = btn.textContent;

          // Cambiar botón
          btn.textContent = "✅ ¡Copiado!";
          btn.style.background = "#20c997";

          // Mostrar tooltip
          clearTimeout(copyTooltipFadeTimeout);
          clearTimeout(copyTooltipHideTimeout);
          tooltip.classList.remove("fade-out");
          tooltip.classList.add("visible");

          // Programar desvanecimiento
          copyTooltipFadeTimeout = setTimeout(function () {
            tooltip.classList.add("fade-out");
            copyTooltipHideTimeout = setTimeout(function () {
              tooltip.classList.remove("visible", "fade-out");
            }, 500);
          }, 2000);

          // Restaurar botón
          setTimeout(function () {
            btn.textContent = originalText;
            btn.style.background = "";
          }, 2500);
        }

        // Intentar copiar con Clipboard API (moderno)
        if (navigator.clipboard && navigator.clipboard.writeText) {
          navigator.clipboard
            .writeText(trackingNumber)
            .then(function () {
              showCopyFeedback();
            })
            .catch(function (err) {

              fallbackCopy();
            });
        } else {
          fallbackCopy();
        }

        // Fallback para navegadores sin Clipboard API
        function fallbackCopy() {
          var textArea = document.createElement("textarea");
          textArea.value = trackingNumber;
          textArea.style.position = "fixed";
          textArea.style.left = "-9999px";
          textArea.style.top = "0";
          document.body.appendChild(textArea);
          textArea.focus();
          textArea.select();

          try {
            var successful = document.execCommand("copy");
            if (successful) {
              showCopyFeedback();
            } else {
              alert(
                "No se pudo copiar. Por favor copia manualmente: " +
                  trackingNumber
              );
            }
          } catch (err) {

            alert(
              "No se pudo copiar. Por favor copia manualmente: " +
                  trackingNumber
            );
          }

          document.body.removeChild(textArea);
        }
      }

      function trackTicketNow() {
        if (currentTrackingId) {
          window.location.href = `/track/${encodeURIComponent(
            currentTrackingId
          )}`;
        }
      }

      function openTrackingSearch() {
        document.getElementById("trackingModal").style.display = "flex";
      }

      function searchTicket() {
        // ❌ Elemento searchTrackingInput no existe en el HTML
        // Esta función no se usa actualmente, pero la mantengo por compatibilidad
        const trackingId = prompt("Ingresa el número de seguimiento:");
        if (trackingId && trackingId.trim()) {
          window.location.href = `/track/${encodeURIComponent(
            trackingId.trim()
          )}`;
        }
      }

      // Check URL parameters for auto-opening login modal
      window.addEventListener("load", async function () {
        const urlParams = new URLSearchParams(window.location.search);
        const error = urlParams.get("error");

        if (
          error === "auth_required" ||
          error === "invalid_token" ||
          error === "access_denied"
        ) {
          openLoginModal();
          const errorMessages = {
            auth_required: "Debes iniciar sesión para acceder",
            invalid_token:
              "Tu sesión ha expirado, por favor inicia sesión nuevamente",
            access_denied: "No tienes permisos para acceder a esta página",
          };
          const loginError = document.getElementById("loginError");
          loginError.textContent =
            errorMessages[error] || "Error de autenticación";
          loginError.style.display = "block";
        }

        // Verificar si el usuario está logueado y actualizar el botón
        try {
          const response = await fetch('/api/auth/verify', {
            credentials: 'include'
          });
          
          if (response.ok) {
            const data = await response.json();
            if (data.user) {
              // Usuario logueado - actualizar botón de login
              updateLoginButtonForLoggedUser(data.user);
            }
          }
        } catch (err) {
          // No hacer nada si falla la verificación

        }
      });

      // Función para actualizar el botón de login cuando el usuario ya está logueado
      function updateLoginButtonForLoggedUser(user) {
        // Mapeo de roles a rutas
        const roleToRoute = {
          administrador: '/administrador',
          gerencia: '/gerencia',
          support: '/support',
          rrhh: '/rrhh',
          mantenimiento: '/mantenimiento',
          compras: '/compras',
          facturacion: '/facturacion',
          contact: '/contact'
        };

        const targetRoute = roleToRoute[user.role] || '/';

        // Buscar el botón de login principal (clase btn-login o id headerLoginBtn)
        const loginBtn = document.querySelector('.btn-login') || document.getElementById('headerLoginBtn');
        if (loginBtn) {
          loginBtn.innerHTML = `👤 ${user.name || 'Panel'} &bull; Ir al Panel`;
          loginBtn.style.background = 'linear-gradient(135deg, #0f766e 0%, #115e59 100%)';
          // Primero eliminar el atributo onclick inline
          loginBtn.removeAttribute('onclick');
          // Luego asignar el nuevo handler
          loginBtn.addEventListener('click', function(e) {
            e.preventDefault();
            window.location.href = targetRoute;
          });
        }

        // Actualizar el texto del section header si existe
        const sectionHeader = document.querySelector('.auth-section');
        if (sectionHeader) {
          const headerH2 = sectionHeader.closest('.container')?.querySelector('.section-header h2');
          const headerP = sectionHeader.closest('.container')?.querySelector('.section-header p');
          if (headerH2) headerH2.innerHTML = '✅ Sesión Activa';
          if (headerP) headerP.textContent = `Bienvenido, ${user.name}`;
        }
      }
