import os
import numpy as np
import tensorflow as tf
from PIL import Image


# ============================================================
# CONFIGURATION
# ============================================================

IMG_SIZE = (224, 224)

MODEL_PATH = os.path.join(
    os.path.dirname(__file__),
    "plant_disease_recog_model_pwp (2).keras"
)


# ============================================================
# 39 MODEL LABELS
# ============================================================

LABELS = [
    "Apple__Apple_scab",
    "Apple_Black_rot",
    "Apple_Cedar_apple_rust",
    "Apple__healthy",
    "Background_without_leaves",
    "Blueberry__healthy",
    "Cherry_Powdery_mildew",
    "Cherry__healthy",
    "Corn__Cercospora_leaf_spot Gray_leaf_spot",
    "Corn_Common_rust",
    "Corn_Northern_Leaf_Blight",
    "Corn__healthy",
    "Grape__Black_rot",
    "Grape_Esca(Black_Measles)",
    "Grape__Leaf_blight(Isariopsis_Leaf_Spot)",
    "Grape___healthy",
    "Orange__Haunglongbing(Citrus_greening)",
    "Peach__Bacterial_spot",
    "Peach__healthy",
    "Pepper,bell_Bacterial_spot",
    "Pepper,_bell__healthy",
    "Potato__Early_blight",
    "Potato_Late_blight",
    "Potato__healthy",
    "Raspberry__healthy",
    "Soybean_healthy",
    "Squash__Powdery_mildew",
    "Strawberry__Leaf_scorch",
    "Strawberry__healthy",
    "Tomato__Bacterial_spot",
    "Tomato_Early_blight",
    "Tomato_Late_blight",
    "Tomato__Leaf_Mold",
    "Tomato__Septoria_leaf_spot",
    "Tomato_Spider_mites Two-spotted_spider_mite",
    "Tomato__Target_Spot",
    "Tomato__Tomato_Yellow_Leaf_Curl_Virus",
    "Tomato_Tomato_mosaic_virus",
    "Tomato__healthy",
]


# ============================================================
# DISEASE INFORMATION
# ============================================================

DISEASE_INFO = {

    "Tomato_Late_blight": {
        "cause": "Caused by Phytophthora infestans and spreads rapidly during cool, moist conditions.",
        "cure": "Use appropriate fungicides; remove infected plant material; improve ventilation.",
    },

    "Tomato_Early_blight": {
        "cause": "Caused by Alternaria solani and commonly spreads through soil splash in humid weather.",
        "cure": "Use appropriate fungicides; stake plants; mulch heavily.",
    },

    "Tomato__Bacterial_spot": {
        "cause": "Caused by Xanthomonas species, commonly spreading during warm, wet conditions.",
        "cure": "Use appropriate copper-based treatments; rotate crops; use disease-free seeds.",
    },

    "Tomato__Leaf_Mold": {
        "cause": "Caused by Passalora fulva and associated with high humidity.",
        "cure": "Improve ventilation; reduce humidity; use resistant varieties.",
    },

    "Tomato__Septoria_leaf_spot": {
        "cause": "Caused by Septoria lycopersici and spreads during wet weather.",
        "cure": "Use appropriate fungicides; rotate crops; remove affected lower leaves.",
    },

    "Tomato_Spider_mites Two-spotted_spider_mite": {
        "cause": "Caused by Tetranychus urticae mites, which thrive in hot, dry conditions.",
        "cure": "Use insecticidal soap or appropriate miticides; increase humidity; encourage natural predators.",
    },

    "Tomato__Target_Spot": {
        "cause": "Caused by Corynespora cassiicola and favored by warm, humid conditions.",
        "cure": "Use appropriate fungicides; sanitize growing areas; avoid overhead irrigation.",
    },

    "Tomato__Tomato_Yellow_Leaf_Curl_Virus": {
        "cause": "Transmitted by whiteflies (Bemisia tabaci).",
        "cure": "Control whiteflies; use reflective mulch; remove infected plants.",
    },

    "Tomato_Tomato_mosaic_virus": {
        "cause": "Caused by Tobacco mosaic virus and can spread through handling and contaminated tools.",
        "cure": "Remove infected plants; sanitize tools; use resistant varieties.",
    },

    "Tomato__healthy": {
        "cause": "No disease detected.",
        "cure": "Provide full sun, even watering and adequate plant support.",
    },

    "Potato__Early_blight": {
        "cause": "Caused by the fungus Alternaria solani.",
        "cure": "Apply appropriate fungicides; rotate crops; maintain plant hygiene.",
    },

    "Potato_Late_blight": {
        "cause": "Caused by Phytophthora infestans, spreading rapidly in cool, moist conditions.",
        "cure": "Use appropriate fungicides; destroy infected volunteers; plant certified seed.",
    },

    "Potato__healthy": {
        "cause": "No disease detected.",
        "cure": "Maintain balanced fertilization; provide adequate spacing and drainage.",
    },

    "Corn_Common_rust": {
        "cause": "Caused by the fungus Puccinia sorghi.",
        "cure": "Plant resistant hybrids; apply appropriate fungicide treatment when required; monitor regularly.",
    },

    "Corn_Northern_Leaf_Blight": {
        "cause": "Caused by Exserohilum turcicum and favored by moderate temperatures and high humidity.",
        "cure": "Use resistant varieties; apply appropriate fungicide treatment; rotate crops.",
    },

    "Corn__healthy": {
        "cause": "No disease detected.",
        "cure": "Maintain fertility with NPK; space plants for airflow; irrigate evenly.",
    },

    "Apple__healthy": {
        "cause": "No disease detected.",
        "cure": "Maintain balanced fertilizer, regular watering, pruning, and monitoring.",
    },

    "Blueberry__healthy": {
        "cause": "No disease detected.",
        "cure": "Continue good crop management and monitor for early signs of disease.",
    },

    "Cherry__healthy": {
        "cause": "No disease detected.",
        "cure": "Maintain good pruning, nutrition, sunlight, and soil drainage.",
    },

    "Grape___healthy": {
        "cause": "No disease detected.",
        "cure": "Maintain balanced pruning, sunlight, airflow, and soil moisture.",
    },

    "Peach__healthy": {
        "cause": "No disease detected.",
        "cure": "Maintain good drainage, nutrition, and regular crop monitoring.",
    },

    "Pepper,_bell__healthy": {
        "cause": "No disease detected.",
        "cure": "Maintain consistent watering, airflow, nutrition, and crop hygiene.",
    },

    "Raspberry__healthy": {
        "cause": "No disease detected.",
        "cure": "Maintain proper spacing, trellising, soil conditions, and monitoring.",
    },

    "Soybean_healthy": {
        "cause": "No disease detected.",
        "cure": "Maintain appropriate row spacing, fertility, irrigation, and weed control.",
    },

    "Strawberry__healthy": {
        "cause": "No disease detected.",
        "cure": "Maintain proper irrigation, soil conditions, mulch, and plant hygiene.",
    },

    "Background_without_leaves": {
        "cause": "The uploaded image does not appear to contain a plant leaf.",
        "cure": "Please upload a clear image of a crop or plant leaf.",
    },
}


# ============================================================
# LOAD MODEL
# ============================================================

model = None

try:
    if not os.path.exists(MODEL_PATH):
        print(f"WARNING: Model file not found: {MODEL_PATH}")
    else:
        model = tf.keras.models.load_model(MODEL_PATH)

        print("Model loaded successfully")
        print(f"Model path: {MODEL_PATH}")
        print(f"Model output shape: {model.output_shape}")

except Exception as e:
    print(f"ERROR loading disease model: {e}")
    model = None


# ============================================================
# IMAGE PREPROCESSING
# ============================================================

def extract_features(image_path: str):
    """
    Load and preprocess image for the 39-class Keras model.
    """

    try:
        image = Image.open(image_path).convert("RGB")

        image = image.resize(IMG_SIZE)

        image_array = np.asarray(image, dtype=np.float32)

        image_array = image_array / 255.0

        image_array = np.expand_dims(
            image_array,
            axis=0
        )

        return image_array

    except Exception as e:
        print(f"Image preprocessing error: {e}")
        return None


# ============================================================
# PREDICTION
# ============================================================

def model_predict(image_path: str) -> dict:
    """
    Run crop disease prediction.

    Returns:
        predicted_class
        confidence
        cause
        cure
    """

    # --------------------------------------------------------
    # STEP 1: Check model
    # --------------------------------------------------------

    if model is None:
        return {
            "predicted_class": "Model unavailable",
            "confidence": 0.0,
            "cause": "The crop disease model could not be loaded.",
            "cure": "Please check the model file and TensorFlow installation.",
        }


    # --------------------------------------------------------
    # STEP 2: Check image
    # --------------------------------------------------------

    if not image_path or not os.path.exists(image_path):
        return {
            "predicted_class": "Image not found",
            "confidence": 0.0,
            "cause": "The uploaded image could not be found.",
            "cure": "Please upload the image again.",
        }


    # --------------------------------------------------------
    # STEP 3: Extract image features
    # --------------------------------------------------------

    img_array = extract_features(image_path)

    if img_array is None:
        return {
            "predicted_class": "Image processing failed",
            "confidence": 0.0,
            "cause": "Could not process the uploaded image.",
            "cure": "Please try with a different crop leaf image.",
        }


    # --------------------------------------------------------
    # STEP 4: Run model
    # --------------------------------------------------------

    try:

        prediction = model.predict(
            img_array,
            verbose=0
        )

        prediction_values = prediction[0]

        print(
            f"Prediction shape: {prediction.shape}"
        )

        idx = int(
            np.argmax(prediction_values)
        )

        # ----------------------------------------------------
        # STEP 5: Validate class index
        # ----------------------------------------------------

        if idx >= len(LABELS):

            return {
                "predicted_class": "Unsupported prediction",
                "confidence": 0.0,
                "cause": "The model produced an unsupported class.",
                "cure": "Please upload a clear crop leaf image.",
            }


        predicted_class = LABELS[idx]

        confidence = float(
            prediction_values[idx]
        )

        # Keep confidence within API range.
        confidence = max(
            0.0,
            min(confidence, 1.0)
        )


        print(
            f"Predicted: {predicted_class}"
        )

        print(
            f"Confidence: {confidence:.4f}"
        )


        # ----------------------------------------------------
        # STEP 6: Background / invalid image
        # ----------------------------------------------------

        if predicted_class == "Background_without_leaves":

            return {
                "predicted_class": "Not a plant image",
                "confidence": confidence,
                "cause": "The uploaded image does not appear to contain a plant leaf.",
                "cure": "Please upload a clear crop leaf image.",
            }


        # ----------------------------------------------------
        # STEP 7: Disease information
        # ----------------------------------------------------

        info = DISEASE_INFO.get(
            predicted_class,
            {
                "cause": "Disease information is not available in the local knowledge base.",
                "cure": "Please consult the crop advisory module for further guidance.",
            }
        )


        # ----------------------------------------------------
        # STEP 8: Final result
        # ----------------------------------------------------

        return {
            "predicted_class": predicted_class,
            "confidence": confidence,
            "cause": info["cause"],
            "cure": info["cure"],
        }


    except Exception as e:

        print(
            f"Prediction error: {e}"
        )

        return {
            "predicted_class": "Prediction failed",
            "confidence": 0.0,
            "cause": f"Model prediction failed: {str(e)}",
            "cure": "Please try another clear crop leaf image.",
        }