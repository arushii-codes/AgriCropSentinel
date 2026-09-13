import numpy as np
import json
import tensorflow as tf
from PIL import Image


# ============================================================
# GLOBAL SETUP
# ============================================================

IMG_SIZE = (224, 224)


# ============================================================
# 39 MODEL LABELS
# ============================================================

label = [
    'Apple__Apple_scab',
    'Apple_Black_rot',
    'Apple_Cedar_apple_rust',
    'Apple__healthy',
    'Background_without_leaves',
    'Blueberry__healthy',
    'Cherry_Powdery_mildew',
    'Cherry__healthy',
    'Corn__Cercospora_leaf_spot Gray_leaf_spot',
    'Corn_Common_rust',
    'Corn_Northern_Leaf_Blight',
    'Corn__healthy',
    'Grape__Black_rot',
    'Grape_Esca(Black_Measles)',
    'Grape__Leaf_blight(Isariopsis_Leaf_Spot)',
    'Grape___healthy',
    'Orange__Haunglongbing(Citrus_greening)',
    'Peach__Bacterial_spot',
    'Peach__healthy',
    'Pepper,bell_Bacterial_spot',
    'Pepper,_bell__healthy',
    'Potato__Early_blight',
    'Potato_Late_blight',
    'Potato__healthy',
    'Raspberry__healthy',
    'Soybean_healthy',
    'Squash__Powdery_mildew',
    'Strawberry__Leaf_scorch',
    'Strawberry__healthy',
    'Tomato__Bacterial_spot',
    'Tomato_Early_blight',
    'Tomato_Late_blight',
    'Tomato__Leaf_Mold',
    'Tomato__Septoria_leaf_spot',
    'Tomato_Spider_mites Two-spotted_spider_mite',
    'Tomato__Target_Spot',
    'Tomato__Tomato_Yellow_Leaf_Curl_Virus',
    'Tomato_Tomato_mosaic_virus',
    'Tomato__healthy'
]


# ============================================================
# DISEASE INFORMATION
# ============================================================

data = {

    'Apple__Apple_scab': {
        'cause': 'Caused by the fungus Venturia inaequalis, which overwinters in infected leaves and spreads via spores in wet spring conditions.',
        'cure': 'Apply fungicides (e.g., captan) during bud break; rake and destroy fallen leaves; choose resistant varieties like Liberty.'
    },

    'Apple_Black_rot': {
        'cause': 'Caused by the fungus Diplodia seriata (syn. Botryosphaeria obtusa), entering through wounds and thriving in warm, humid conditions.',
        'cure': 'Sanitation: Remove infected fruit and cankers; apply copper-based fungicides early season; prune for air circulation.'
    },

    'Apple_Cedar_apple_rust': {
        'cause': 'Caused by the fungus Gymnosporangium juniperi-virginianae, requiring alternating hosts (apple and cedar/juniper) for its life cycle.',
        'cure': 'Remove nearby cedars/juniper galls; apply myclobutanil fungicide at bud break; plant resistant apples like Enterprise.'
    },

    'Apple__healthy': {
        'cause': 'No disease detected; healthy leaves indicate proper care and resistance.',
        'cure': 'Maintain with balanced fertilizer, regular watering, and pruning; monitor for early signs of issues.'
    },

    'Background_without_leaves': {
        'cause': 'Not a disease; this class represents images without plant leaves.',
        'cure': 'Upload a clear image of plant leaves for analysis; ensure good lighting and focus on foliage.'
    },

    'Blueberry__healthy': {
        'cause': 'No disease detected.',
        'cure': 'Continue good practices: acidic soil (pH 4.5-5.5), mulch, and net against birds.'
    },

    'Cherry_Powdery_mildew': {
        'cause': 'Caused by the fungus Podosphaera clandestina, favoring cool, dry conditions on young leaves.',
        'cure': 'Apply sulfur-based fungicides; improve air flow by pruning; water at base to keep foliage dry.'
    },

    'Cherry__healthy': {
        'cause': 'No disease detected.',
        'cure': 'Prune annually for shape; fertilize in spring; ensure full sun and well-drained soil.'
    },

    'Corn__Cercospora_leaf_spot Gray_leaf_spot': {
        'cause': 'Caused by the fungus Cercospora zeae-maydis, spreading in warm, humid weather via spores on debris.',
        'cure': 'Rotate crops; apply fungicides like azoxystrobin; remove infected residue post-harvest.'
    },

    'Corn_Common_rust': {
        'cause': 'Caused by the fungus Puccinia sorghi, with spores overwintering on alternate hosts like oxalis.',
        'cure': 'Plant resistant hybrids; apply triazoles early; destroy volunteer corn.'
    },

    'Corn_Northern_Leaf_Blight': {
        'cause': 'Caused by the fungus Exserohilum turcicum, thriving in moderate temperatures and high humidity.',
        'cure': 'Use resistant varieties; apply propiconazole at tasseling; rotate with non-host crops.'
    },

    'Corn__healthy': {
        'cause': 'No disease detected.',
        'cure': 'Maintain fertility with NPK; space plants for air flow; irrigate evenly.'
    },

    'Grape__Black_rot': {
        'cause': 'Caused by the fungus Guignardia bidwellii, spores spread by rain from infected debris.',
        'cure': 'Apply mancozeb pre-bloom; prune for canopy openness; sanitize tools.'
    },

    'Grape_Esca(Black_Measles)': {
        'cause': 'Caused by a complex of fungi entering through pruning wounds.',
        'cure': 'Delay pruning until dry weather; remove infected vines.'
    },

    'Grape__Leaf_blight(Isariopsis_Leaf_Spot)': {
        'cause': 'Caused by fungal leaf spot that spreads under wet conditions.',
        'cure': 'Use appropriate fungicides; mulch to reduce soil splash; remove lower infected leaves.'
    },

    'Grape___healthy': {
        'cause': 'No disease detected.',
        'cure': 'Trellis for sun exposure; balanced pruning; monitor soil moisture.'
    },

    'Orange__Haunglongbing(Citrus_greening)': {
        'cause': 'Caused by the bacterium Liberibacter asiaticus, transmitted by Asian citrus psyllid.',
        'cure': 'Remove infected trees; control psyllids; focus on prevention because there is no cure.'
    },

    'Peach__Bacterial_spot': {
        'cause': 'Caused by Xanthomonas arboricola pv. pruni, spread by rain and splashing.',
        'cure': 'Copper sprays at bud swell; choose resistant varieties; avoid overhead watering.'
    },

    'Peach__healthy': {
        'cause': 'No disease detected.',
        'cure': 'Thin fruit for size; fertilize post-harvest; ensure good drainage.'
    },

    'Pepper,bell_Bacterial_spot': {
        'cause': 'Caused by Xanthomonas species, entering through wounds in warm, wet conditions.',
        'cure': 'Use copper bactericides; rotate crops; use disease-free seeds.'
    },

    'Pepper,_bell__healthy': {
        'cause': 'No disease detected.',
        'cure': 'Stake for air flow; consistent watering; mulch to suppress weeds.'
    },

    'Potato__Early_blight': {
        'cause': 'Caused by the fungus Alternaria solani.',
        'cure': 'Apply appropriate fungicides; rotate crops; maintain plant hygiene.'
    },

    'Potato_Late_blight': {
        'cause': 'Caused by Phytophthora infestans, spreading rapidly in cool, moist conditions.',
        'cure': 'Use appropriate fungicides; destroy infected volunteers; plant certified seed.'
    },

    'Potato__healthy': {
        'cause': 'No disease detected.',
        'cure': 'Maintain balanced fertilization; provide adequate spacing and drainage.'
    },

    'Raspberry__healthy': {
        'cause': 'No disease detected.',
        'cure': 'Trellis canes; thin annually; maintain appropriate soil conditions.'
    },

    'Soybean_healthy': {
        'cause': 'No disease detected.',
        'cure': 'Inoculate seeds; maintain appropriate row spacing; control weeds.'
    },

    'Squash__Powdery_mildew': {
        'cause': 'Caused by Podosphaera xanthii.',
        'cure': 'Use appropriate fungicides; improve air circulation; use resistant varieties.'
    },

    'Strawberry__Leaf_scorch': {
        'cause': 'Caused by the fungus Diplocarpon earliae, with spores spreading through wet foliage.',
        'cure': 'Apply appropriate fungicides; improve drainage; remove old infected leaves.'
    },

    'Strawberry__healthy': {
        'cause': 'No disease detected.',
        'cure': 'Maintain proper mulch, soil conditions, irrigation and plant hygiene.'
    },

    'Tomato__Bacterial_spot': {
        'cause': 'Caused by Xanthomonas species, commonly spreading during warm, wet conditions.',
        'cure': 'Use appropriate copper-based treatments; rotate crops; use disease-free seeds.'
    },

    'Tomato_Early_blight': {
        'cause': 'Caused by Alternaria solani and commonly spreads through soil splash in humid weather.',
        'cure': 'Use appropriate fungicides; stake plants; mulch heavily.'
    },

    'Tomato_Late_blight': {
        'cause': 'Caused by Phytophthora infestans and spreads rapidly during cool, moist conditions.',
        'cure': 'Use appropriate fungicides; remove infected plant material; improve ventilation.'
    },

    'Tomato__Leaf_Mold': {
        'cause': 'Caused by Passalora fulva and associated with high humidity.',
        'cure': 'Improve ventilation; reduce humidity; use resistant varieties.'
    },

    'Tomato__Septoria_leaf_spot': {
        'cause': 'Caused by Septoria lycopersici and spreads during wet weather.',
        'cure': 'Use appropriate fungicides; rotate crops; remove affected lower leaves.'
    },

    'Tomato_Spider_mites Two-spotted_spider_mite': {
        'cause': 'Caused by Tetranychus urticae mites, which thrive in hot, dry conditions.',
        'cure': 'Use insecticidal soap or appropriate miticides; increase humidity; encourage natural predators.'
    },

    'Tomato__Target_Spot': {
        'cause': 'Caused by Corynespora cassiicola and favored by warm, humid conditions.',
        'cure': 'Use appropriate fungicides; sanitize growing areas; avoid overhead irrigation.'
    },

    'Tomato__Tomato_Yellow_Leaf_Curl_Virus': {
        'cause': 'Transmitted by whiteflies (Bemisia tabaci).',
        'cure': 'Control whiteflies; use reflective mulch; remove infected plants.'
    },

    'Tomato_Tomato_mosaic_virus': {
        'cause': 'Caused by Tobacco mosaic virus and can spread through handling and contaminated tools.',
        'cure': 'Remove infected plants; sanitize tools; use resistant varieties.'
    },

    'Tomato__healthy': {
        'cause': 'No disease detected.',
        'cure': 'Provide full sun, even watering and adequate plant support.'
    }
}


# ============================================================
# LOAD DISEASE DICTIONARY
# ============================================================

plant_disease = [
    {
        'name': disease_name,
        'cause': info['cause'],
        'cure': info['cure']
    }
    for disease_name, info in data.items()
]

try:

    with open(
        "plant_disease.json",
        "r",
        encoding="utf-8"
    ) as file:

        plant_disease = json.load(file)

    disease_dict = {
        disease['name']: disease
        for disease in plant_disease
    }

    print("✅ Disease dictionary loaded successfully")

except Exception as e:

    print(f"⚠️ Could not load plant_disease.json: {e}")

    # Use the built-in disease information instead
    disease_dict = data.copy()

    print("✅ Using built-in disease dictionary")


# ============================================================
# LOAD MODEL
# ============================================================

try:

    model = tf.keras.models.load_model(
        "image_analysis/plant_disease_recog_model_pwp (2).keras"
    )

    print("✅ Model loaded successfully")

    # Print model output shape for debugging
    try:
        print(f"🧠 Model output shape: {model.output_shape}")
    except Exception:
        pass

except Exception as e:

    print(f"❌ Error loading model: {e}")

    model = None


# ============================================================
# IMAGE PREPROCESSING
# ============================================================

def extract_features(image_path: str):

    try:

        img = Image.open(image_path).convert("RGB")

        img = img.resize(IMG_SIZE)

        img_array = np.array(img)

        img_array = tf.keras.applications.efficientnet.preprocess_input(
            img_array
        )

        img_array = np.expand_dims(
            img_array,
            axis=0
        )

        return img_array

    except Exception as e:

        print(f"❌ Error extracting features: {e}")

        return None


# ============================================================
# BASIC PLANT IMAGE VALIDATION
# ============================================================

def is_likely_plant_image(image_path: str):

    """
    Performs a basic visual check before sending the image
    to the disease classifier.

    IMPORTANT:
    This is a lightweight first-pass filter.
    It is NOT a replacement for a dedicated plant/non-plant model.
    """

    try:

        img = Image.open(image_path).convert("RGB")

        img = img.resize((224, 224))

        img_array = np.array(img).astype(
            np.float32
        ) / 255.0

        red = img_array[:, :, 0]
        green = img_array[:, :, 1]
        blue = img_array[:, :, 2]

        # Pixels where green is noticeably stronger
        # than red and blue.
        green_pixels = (
            (green > red * 1.05)
            &
            (green > blue * 1.05)
            &
            (green > 0.20)
        )

        green_ratio = float(
            np.mean(green_pixels)
        )

        # Overall image statistics
        mean_red = float(np.mean(red))
        mean_green = float(np.mean(green))
        mean_blue = float(np.mean(blue))

        print(
            "🌿 Image check -> "
            f"R:{mean_red:.3f}, "
            f"G:{mean_green:.3f}, "
            f"B:{mean_blue:.3f}, "
            f"Green ratio:{green_ratio:.3f}"
        )

        # Very low amount of plant-like green
        if green_ratio < 0.03:

            print(
                "🚫 Image rejected: "
                "not enough plant-like pixels."
            )

            return False

        return True

    except Exception as e:

        print(
            f"❌ Image validation error: {e}"
        )

        return False


# ============================================================
# MODEL PREDICTION
# ============================================================

def model_predict(image_path: str):

    # --------------------------------------------------------
    # STEP 1: Validate image
    # --------------------------------------------------------

    if not is_likely_plant_image(image_path):

        return {
            "predicted_class": "Not a plant image",
            "confidence": 0.0,
            "cause": (
                "The uploaded image does not appear "
                "to contain a plant leaf."
            ),
            "cure": (
                "Please upload a clear image of "
                "a crop or plant leaf."
            )
        }


    # --------------------------------------------------------
    # STEP 2: Check model
    # --------------------------------------------------------

    if model is None:

        return {
            "predicted_class": "Model unavailable",
            "confidence": 0.0,
            "cause": "Model not loaded properly.",
            "cure": "Please check the model file."
        }


    # --------------------------------------------------------
    # STEP 3: Extract image features
    # --------------------------------------------------------

    img_array = extract_features(
        image_path
    )

    if img_array is None:

        return {
            "predicted_class": "Image processing failed",
            "confidence": 0.0,
            "cause": "Could not process the uploaded image.",
            "cure": "Please try with a different image."
        }


    # --------------------------------------------------------
    # STEP 4: Run CNN
    # --------------------------------------------------------

    try:

        prediction = model.predict(
            img_array,
            verbose=0
        )

        print(
            f"🔍 Prediction shape: "
            f"{prediction.shape}"
        )

        print(
            f"🔍 Raw probabilities: "
            f"{prediction[0]}"
        )

        idx = int(
            np.argmax(
                prediction[0]
            )
        )

        print(
            f"🔍 Argmax index: {idx}"
        )


        # ----------------------------------------------------
        # STEP 5: Safely handle model output
        # ----------------------------------------------------

        if idx >= len(label):

            print(
                "⚠️ Model output index is outside "
                "the label list."
            )

            return {
                "predicted_class": "Not a plant image",
                "confidence": 0.0,
                "cause": (
                    "The model produced an unsupported "
                    "prediction class."
                ),
                "cure": (
                    "Please upload a clear crop leaf image."
                )
            }


        predicted_class_name = label[idx]

        confidence = float(
            prediction[0][idx]
        )

        print(
            f"🔍 Predicted: "
            f"{predicted_class_name}, "
            f"Confidence: {confidence:.4f}"
        )


        # ----------------------------------------------------
        # STEP 6: Background class
        # ----------------------------------------------------

        if (
            predicted_class_name
            == "Background_without_leaves"
        ):

            return {
                "predicted_class": "Not a plant image",
                "confidence": confidence,
                "cause": (
                    "The uploaded image does not appear "
                    "to contain a plant leaf."
                ),
                "cure": (
                    "Please upload a clear image of "
                    "a crop or plant leaf."
                )
            }


        # ----------------------------------------------------
        # STEP 7: Get disease information
        # ----------------------------------------------------

        prediction_info = disease_dict.get(
            predicted_class_name,
            {}
        )


        # ----------------------------------------------------
        # STEP 8: Return result
        # ----------------------------------------------------

        return {

            "predicted_class":
                predicted_class_name,

            "confidence":
                confidence,

            "cause":
                prediction_info.get(
                    "cause",
                    "Information not available"
                ),

            "cure":
                prediction_info.get(
                    "cure",
                    "Information not available"
                )
        }


    # --------------------------------------------------------
    # STEP 9: Error handling
    # --------------------------------------------------------

    except Exception as e:

        print(
            f"❌ Error during prediction: {e}"
        )

        import traceback

        print(
            traceback.format_exc()
        )

        return {

            "predicted_class":
                "Prediction failed",

            "confidence":
                0.0,

            "cause":
                f"Error during prediction: {e}",

            "cure":
                "Please try again."
        }