import ocrmypdf
import os
from PyPDF2 import PdfReader
import tempfile

input_pdf = "/home/jye/06_Hackathon/bochackathon/web_service/static/bills/Eletricity.pdf"

if os.path.exists(input_pdf):
    with tempfile.NamedTemporaryFile(delete=False, suffix='.pdf') as temp_output:
        try:
            ocrmypdf.ocr(input_pdf, temp_output.name, deskew=True)
            
            with open(temp_output.name, 'rb') as f:
                pdf_reader = PdfReader(f)
                text = ''
                for page in pdf_reader.pages:
                    text += page.extract_text()
            
            print(text)  # Print extracted text
            
        except Exception as e:
            print(f"Error: {e}")
