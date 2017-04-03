class BotLogic < BaseBotLogic
	
	def self.setup
		set_welcome_message "Hola! Soy Myriam, tu asistente de Vecinity."
		set_get_started_button "bot_start_payload"
		set_bot_menu %W(Reset Ayuda)
	end

	def self.cron
		broadcast_all ":princess:"
	end

	def self.bot_logic

		@first_name = get_profile(@current_user.fb_id)["first_name"]

		if @request_type == "CALLBACK"
      		case @fb_params.payload
      			when "RESET_BOT"
	        		reply_message "Oh lo siento, me quedé atascada. Ya debería estar de vuelta! :smile:"
	        		state_go 1
        		return
        		when "AYUDA_BOT"
        			list_instructions
        		return 
        		when "bot_start_payload"
        		reply_message "Hola #{@first_name}"
        		reply_quick_reply "Ya me conoces, o quieres que te cuente quien soy?:blush:", ['Cuéntame', 'Ya te conozco']
        		state_go 0
        		return
        		
      	end
    end
    	state_action 0, :greet
		state_action 1, :convo_root
		state_action 2, :new_report
		state_action 3, :handle_location
		state_action 4, :handle_description
		state_action 5, :confirmation
	end

	def self.greet
		onboarding = get_message
		puts 'onboarding'
		case onboarding
		when "Cuéntame"
			typing_indicator   
			reply_message "Genial, es muy fácil :blush:"
			sleep(1)
        	reply_message "Soy Myriam, tu asistente de Vecinity. Te ayudo a hacer tus denuncias en un periquete.:heart_eyes:"
        	reply_quick_reply "Sólo me tienes que mandar una foto de lo que quieras denunciar, y yo te guío con lo demás.", ["Vale!"]
        when "Vale!"
        	reply_message "Para hacer una denuncia tienes que estar en el sitio exacto donde veas la infracción. :smile:"
        	reply_message "Recuerda que en cualquier momento puedes poner AYUDA si te pierdes"
        	state_go 
		when "I got it"
			reply_message "Genial #{@first_name}, pues aqui estoy para lo que necesites! :smile:"
        	state_go 1
		else
			"Hmmm no he pillado eso. You can type HELP at any time if you have any trouble"
			state_go 1
		end
	end

	def self.convo_root
		@user_says = get_message
		typing_indicator
		if @request_type === "IMAGE"
			new_report
		else
			ai_response = ai_response(@user_says)
			ai_intent = ai_response[:result][:metadata][:intentName]
			ai_reply = ai_response[:result][:fulfillment][:speech].to_s
			ai_score = ai_response[:result][:score]

			if ai_intent == 'help'
				list_instructions
			elsif ai_intent == 'greeting' || ai_intent == 'farewell' ||  ai_intent == 'agreement' || ai_intent == 'gratitude'
				ai_reply = sprintf(ai_reply, @first_name)
				reply_message ai_reply
			elsif ai_intent == 'newReport'
				reply_message "Estupendo! Lo primero que necesito es una foto del problema!"
				state_go 2
			elsif ai_intent == 'insultDefense' && ai_score > 0.9
				ai_reply = sprintf(ai_reply, @first_name)
				reply_image ['http://i.giphy.com/l3q2SaisWTeZnV9wk.gif', 'http://i.giphy.com/3rg3vxFMGGymk.gif'].sample
				reply_message ai_reply
			else 
				reply_message ["Lo siento #{@first_name}, No he entendido eso :cry:. Por favor escribe 'ayuda' si tienes algún problema",
					"Oh vaya #{@first_name}, no te he entendido. Puedes pedirme ayuda si tienes cualquier problema."].sample
			end	
		end
		typing_off	
	end


	def self.new_report
		puts @request_type
		puts @msg_meta
		@report = {}
		if @request_type == "IMAGE"
			puts @report
			@report["image"] = @msg_meta
			reply_message "Perfect :smile:"
			reply_message "Recuerda que Vecinity sólo vale si estás en la ubicación de la denuncia."
			reply_location_button "Si es así, dale al botón para mandarmela! :blush:"
			state_go 3
		else
			reply_message "Hmmmm, eso no es una foto :confused:, volvamos a empezar"
			state_go 1
		end
	end

	def self.handle_location
		@report["location"] = @msg_meta
		reply_message "Esupendo! :smile:, ahora describe lo que quieres que se arregle. Por ejemplo: 'Esta farola lleva fundida un mes!'"
		reply_message "Tienes 140 caracteres para hacerlo! Como en Twitter jeje :blush:"
		state_go 4
	end

	def self.handle_description
		description = get_message
		if description.length > 140
			"Oooops, te has pasado un poco, llevas #{description.length} caracteres :sweat:. Si puedes hacerla un poco más corta mejor!"
			"Vuelve a intentarlo!:smile:"
			puts "Should stop"
			state_go 4
		else
			puts @report, 'PRE'
			@report["message"] = description
			address = get_address_from_latlng(@report["location"])
			reply_message "Genial!"
			reply_message "Repasemos tu denuncia!"
			typing_indicator
			reply_message "Descripición: #{@report["message"]}\nDirección: #{address}"
			reply_image @report["image"]
			reply_quick_reply "Todo bien? :blush:", ["Si", "No"]
			state_go 5
		end
	end

	def self.confirmation
		confirmation_status = get_message
		reply_message "Gracias!"
		case confirmation_status
		when "Si"
			reply_message "Yuju! :blush:"
			reply_message "Informe guardado, te mantendremos al día con el estado de tu denuncia. Visita vecinity.org para ver más :smile:"
			return
		when "No"
			reply_message "Oooops:cry:"
			reply_message "Cancelo la denuncia pues, puedes volver a repetirla si lo deseas!"
			return
		else 
			reply_quick_reply "Porfa, toca una de las opciones", ["Si", "No"]
			state_go 5
		end
		state_go 1
	end

	def self.list_instructions
		typing_indicator
		reply_message "Soy Myriam, y soy tu ayudante para poner denuncias en Vecinity."
		reply_message "Sólo tienes que mandarme una foto de lo que quieras denunciar y listo! Yo te guío en lo demás :blush:"
		sleep(1)
		typing_indicator
		reply_message "Es importante que la denuncia la hagas en el lugar donde la ves, porque así es como las geolocalizamos! :blush:"
		reply_message "Gracias por ayudar a mejorar tu vecindario!"
		typing_off
	end

	## End support functions

end

