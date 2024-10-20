from flask import Flask, jsonify
import ocrmypdf
import os
import tempfile
import re
from PyPDF2 import PdfReader

app = Flask(__name__)

def extract_bill_info(text):
    # Patterns for the required information
    account_number_pattern = r"Αριθμός Λογαριασμού\s*(\d{3}\s*\d{3}\s*\d{4}\s*\d)"
    check_digits_pattern = r"Ψηφία Ελέγχου\s*(\d{3})"
    payment_amount_pattern = r"Ποσόπληρωμής\s*€(\d+,\d{2})"

    # Extract information
    account_number = re.search(account_number_pattern, text)
    check_digits = re.search(check_digits_pattern, text)
    payment_amount = re.search(payment_amount_pattern, text)

    # Prepare results
    results = {}
    if account_number:
        results['Αριθμός Λογαριασμού'] = account_number.group(1).replace(' ', '')
    if check_digits:
        results['Ψηφία Ελέγχου'] = check_digits.group(1)
    if payment_amount:
        results['Ποσόπληρωμής'] = payment_amount.group(1)

    return results

@app.route('/ocr', methods=['GET'])
def ocr_pdf():
    input_pdf = "/home/jye/06_Hackathon/bochackathon/web_service/static/bills/Eletricity.pdf"
    
    if not os.path.exists(input_pdf):
        return jsonify({'error': 'Input PDF file not found'}), 404

    with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as temp_output:
        try:
            ocrmypdf.ocr(input_pdf, temp_output.name, deskew=True)
            
            # Extract text from the OCR'd PDF
            with open(temp_output.name, 'rb') as f:
                pdf_reader = PdfReader(f)
                text = ''
                for page in pdf_reader.pages:
                    text += page.extract_text()
            
            # Extract bill information
            bill_info = extract_bill_info(text)
            
            return jsonify(bill_info), 200
        
        except Exception as e:
            return jsonify({'error': str(e)}), 500
        
        finally:
            os.unlink(temp_output.name)

if __name__ == '__main__':
    app.run(debug=True)
