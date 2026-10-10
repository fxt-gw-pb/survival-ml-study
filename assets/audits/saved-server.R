function (input, output, session) 
{
    observeEvent(input$predict, {
        newdata <- data.frame(Age = as.numeric(input$Age), Race = as.numeric(input$Race), 
            Grade = as.numeric(input$Grade), Surgery = as.numeric(input$Surgery), 
            Chemotherapy = as.numeric(input$Chemotherapy), Marital = as.numeric(input$Marital), 
            SEER_stage = as.numeric(input$SEER_stage), Tumor_size = as.numeric(input$Tumor_size))
        newdata <- newdata[, plsRcox_vars]
        newdata <- as.data.frame(lapply(newdata, as.numeric))
        risk <- predict(plsRcox, newdata = as.matrix(newdata), 
            type = "risk")
        risk <- as.numeric(risk)
        print("Risk:")
        print(risk)
        years <- 1:5
        months <- years * 12
        base <- summary(plsRcox_base)
        base_surv <- approx(x = base$time, y = base$surv, xout = months, 
            method = "constant", rule = 2)$y
        surv_prob <- base_surv^risk
        result <- data.frame(Year = paste0(years, " Year"), Survival = paste0(round(surv_prob * 
            100, 2), "%"))
        output$surv_table <- renderTable({
            result
        })
        curve <- data.frame(Year = years, Survival = surv_prob)
        output$surv_curve <- renderPlot({
            ggplot(curve, aes(Year, Survival)) + geom_line(linewidth = 1) + 
                geom_point(size = 3) + scale_y_continuous(limits = c(0, 
                1), labels = percent) + scale_x_continuous(breaks = 1:5) + 
                theme_classic(base_size = 14) + labs(x = "Years", 
                y = "Survival probability")
        })
    })
}
