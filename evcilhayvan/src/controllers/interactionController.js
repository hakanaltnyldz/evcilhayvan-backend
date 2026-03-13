import Interaction from "../models/Interaction.js";
import { sendOk, sendError } from "../utils/apiResponse.js";

// POST /api/interactions/like/:petId
export async function likePet(req, res) {
  try {
    const userId = req.user.sub;
    const { petId } = req.params;

    await Interaction.findOneAndUpdate(
      { fromUser: userId, toPet: petId },
      { type: "like" },
      { upsert: true, new: true }
    );

    return sendOk(res, 200, { message: "Begeni kaydedildi" });
  } catch (err) {
    return sendError(res, 500, err.message, "interaction_error");
  }
}

// POST /api/interactions/pass/:petId
export async function passPet(req, res) {
  try {
    const userId = req.user.sub;
    const { petId } = req.params;

    await Interaction.findOneAndUpdate(
      { fromUser: userId, toPet: petId },
      { type: "pass" },
      { upsert: true, new: true }
    );

    return sendOk(res, 200, { message: "Pas kaydedildi" });
  } catch (err) {
    return sendError(res, 500, err.message, "interaction_error");
  }
}
