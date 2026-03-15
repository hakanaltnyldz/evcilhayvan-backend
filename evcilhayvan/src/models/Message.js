// src/models/Message.js
import mongoose from "mongoose";
const { Schema } = mongoose;

const messageSchema = new Schema(
  {
    conversationId: {
      type: Schema.Types.ObjectId,
      ref: "Conversation",
      required: true,
      index: true,
    },
    senderId: {
      type: Schema.Types.ObjectId,
      ref: "User",
    },
    sender: {
      type: Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    text: {
      type: String,
      default: '',
      trim: true,
    },
    imageUrl: {
      type: String,
      default: null,
    },
    audioUrl: {
      type: String,
      default: null,
    },
    type: {
      type: String,
      enum: ["TEXT", "IMAGE", "AUDIO", "SYSTEM"],
      default: "TEXT",
      index: true,
    },
    reactions: {
      type: Map,
      of: [{ type: mongoose.Schema.Types.ObjectId, ref: "User" }],
      default: {},
    },
    readBy: {
      type: [Schema.Types.ObjectId],
      ref: "User",
      default: [],
    },
    deletedFor: {
      type: [Schema.Types.ObjectId],
      ref: "User",
      default: [],
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform(_doc, ret) {
        ret.id = ret._id;
        if (ret.senderId) ret.senderId = ret.senderId.toString();
        delete ret._id;
        delete ret.__v;
        return ret;
      },
    },
  }
);

messageSchema.pre("validate", function mapSender(next) {
  if (!this.senderId && this.sender) {
    this.senderId = this.sender;
  }
  if (!this.sender && this.senderId) {
    this.sender = this.senderId;
  }
  next();
});

export default mongoose.model("Message", messageSchema);
