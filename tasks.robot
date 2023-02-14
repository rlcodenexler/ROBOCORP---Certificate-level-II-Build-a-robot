*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.

Library           RPA.Browser.Selenium
Library    RPA.HTTP
Library    RPA.Tables
Library    String
Library    RPA.PDF
Library    RPA.Archive
Library    Dialogs
Library    RPA.Dialogs


*** Variables ***
${OUTPUT_DIR}    ${CURDIR}${/}output

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Input form dialog
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${row}[Order number]
        Go to order another robot
    END
    Create a ZIP file of the receipts

*** Keywords ***
Open the robot order website
    Open Chrome Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    Download    https://robotsparebinindustries.com/orders.csv    ${OUTPUT_DIR}
    ${orders}=    Read table from CSV    ${OUTPUT_DIR}${/}orders.csv
    RETURN    ${orders}

Close the annoying modal
    Wait Until Page Contains Element    locator=//button[text()='OK']
    Click Element    locator=//button[text()='OK']

Fill the form
    [Arguments]    ${row}
    Select From List By Value    xpath=//select[@id='head']    ${row}[Head]
    Click Element    xpath=//input[@type='radio'][@value='${row}[Body]']
    Input Text    xpath=//input[@placeholder='Enter the part number for the legs']    ${row}[Legs]
    Input Text    xpath=//input[@placeholder='Shipping address']    ${row}[Address]

Preview the robot
    Click Element    xpath=//button[normalize-space(text())='Preview']

Submit the order
    [Arguments]    ${order_number}
    Click Element    xpath=//button[@id='order']
    ${alert}=    Does Page Contain Element    //div[@role="alert"]    count=1
    IF    ${alert} == ${True}
        ${alert}=    Set Variable    ${False}
        Submit the order    ${order_number}       
    END
    Wait Until Page Contains Element    xpath=//div[@id='receipt']


Store the receipt as a PDF file
    [Arguments]    ${order_number}
    [Documentation]    Saves the order HTML receipt as a PDF file.
    ${receipt}=    Submit the order    ${order_number}
    ${receipt_html}=    Get Element Attribute    //div[@id='receipt']    outerHTML
    ${pdf}=    Html To Pdf    ${receipt_html}    ${OUTPUT_DIR}${/}${order_number}.pdf
    RETURN    ${pdf}

Take a screenshot of the robot
    [Arguments]    ${order_number}
    [Documentation]    Saves the screenshot of the ordered robot.
    ${screenshot}=    Screenshot    xpath=//div[@id='robot-preview-image']    ${OUTPUT_DIR}${/}${order_number}.png
    RETURN    ${screenshot}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${orderNumber}
    ${images}=    Create List    ${OUTPUT_DIR}${/}${order_number}.png
    # add the robot image to the PDF file
    # Open Pdf    ${OUTPUT_DIR}${/}${orderNumber}.pdf
    Add Files To Pdf    ${images}    ${OUTPUT_DIR}${/}${orderNumber}.pdf    append=True
    # Close Pdf
    

Go to order another robot
    Click Element    xpath=//button[@id='order-another']

Create a ZIP file of the receipts
    ${zip}=    Archive Folder With Zip    ${OUTPUT_DIR}    ${OUTPUT_DIR}${/}receipts.zip

Input form dialog
    Add heading       Send feedback
    Add text input    email    label=E-mail address
    Add text input    message
    ...    label=Feedback
    ...    placeholder=Enter feedback here
    ...    rows=5
    ${result}=    Run dialog
    Log    ${result.email} ${result.message}