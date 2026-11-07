import jwt from 'jsonwebtoken';
import bcrypt from 'bcryptjs';
import { RegisterInput, LoginInput } from './auth.validation.js';
import { prisma } from '../../config/database.js';
import { env } from '../../config/env.js';
import { BadRequestError, UnauthorizedError } from '../../common/errors/app-error.js';

export class AuthService {
  public async register(input: RegisterInput) {
    const existing = await prisma.user.findUnique({
      where: { email: input.email },
    });

    if (existing) {
      throw new BadRequestError('Email sudah terdaftar dalam sistem');
    }

    // Secure password hashing with bcryptjs (salt rounds: 10)
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(input.password, salt);

    const user = await prisma.user.create({
      data: {
        email: input.email,
        passwordHash,
        fullName: input.fullName,
      },
      select: {
        id: true,
        email: true,
        fullName: true,
        createdAt: true,
      },
    });

    const token = jwt.sign(
      { userId: user.id, email: user.email },
      env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    return { user, token };
  }

  public async login(input: LoginInput) {
    const user = await prisma.user.findUnique({
      where: { email: input.email },
    });

    if (!user) {
      throw new UnauthorizedError('Kredensial tidak valid');
    }

    const isMatch = await bcrypt.compare(input.password, user.passwordHash);
    if (!isMatch) {
      throw new UnauthorizedError('Kredensial tidak valid');
    }

    const token = jwt.sign(
      { userId: user.id, email: user.email },
      env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    return {
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        avatarUrl: user.avatarUrl,
      },
      token,
    };
  }
}

export const authService = new AuthService();

